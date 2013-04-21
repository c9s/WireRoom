# -*- cperl -*-
# vim:filetype=perl:et:
package XDMeta;
use Moose;


has clients => ( is => 'rw' , 
    isa => 'HashRef' , 
    traits => [ 'Hash' ],
    default => sub { +{  } },
    handles => {
        set_client => 'set',
        get_client => 'get',
        remove_client => 'delete',
    }
);

sub get_client_list {
    my $self = shift;

    return [ map { {
        nickname => $_->{nickname},
        time     => $_->{time},
    } } values %{ $self->clients } ];
}

__PACKAGE__->meta->make_immutable;
package main;
use warnings;
use strict;
use lib 'lib';
use HTML::Entities;
use WireRoom::Message::Builder;
use Moose;
use Plack::Builder;
use Plack::Request;
use Web::JenkinsNotification;
use Web::ApacheStatus;
use Plack::App::Cascade;
use GitHub::PostReceive;
use Plack::App::Directory;
use JSON;
use Text::Xslate;
use Web::Hippie::App::JSFiles;
use Encode qw(encode_utf8);
use constant debug => 1;

use AnyMQ;
use AnyMQ::Topic;
use Text::Xslate qw(mark_raw);

use WireRoom::Logger;
use HTML::Entities;

use DateTime;
use DateTime::Format::Atom;
use YAML::Syck;

my $config = LoadFile 'config/config.yml';

my $meta = XDMeta->new;
my $bus = AnyMQ->new;
my $topic = AnyMQ::Topic->with_traits('WithBacklog')->new(backlog_length => 200 , bus => $bus);
$bus->topics->{"arena"} = $topic;

my $log_root = 'public/logs';



# XXX: ideal API
# my $logger = WireRoom::Logger->new( 
#     database => $db , 
#     topics => [ $topic ]  # log these topics
# );
# $logger->republish_log($topic);

my $mongo_logger = WireRoom::Logger->new;
$mongo_logger->publish_to( $topic );   # publish to queue
$mongo_logger->log_from( $bus , $topic );

use HTML::Strip;
my $hs = HTML::Strip->new;
mkdir $log_root unless -e $log_root;

my $logger = $bus->new_listener($topic);
$|++;
$logger->poll(sub {
    my @msgs = @_;
    my $now = DateTime->now;

    open my $log , '>>' , $log_root . "/chat-@{[ $now->year ]}-@{[ $now->month ]}-@{[ $now->day ]}.log" or die $!;
    for ( grep { $_->{type} && $_->{type} eq 'says' } grep { ! $_->{log} } @msgs ) {
        my $d = $_->{time} 
                ? DateTime->from_epoch( epoch => $_->{time} )
                : DateTime->now;
        $d->set_time_zone('Asia/Taipei');
        $d->set_formatter( DateTime::Format::Atom->new );

        my $text = $hs->parse( $_->{html} || '' );
        $hs->eof;
        print $log sprintf "%10s %10s %5s %s\n", 
            $d,
            ($_->{nickname} || ''),
            ($_->{verb} || $_->{type}),
            ($text);
    }
    close $log;
});

my $tx = Text::Xslate->new(
    path => [ 'templates' ],
    cache => 1,
    cache_dir => 'cache',
);

$topic->publish({
    type => 'says',
    time => time,
    nickname => 'xdroot',
    html => "Welcome to WireRoom.",
});


sub dispatch_verb {
    my ( $topic, $msg ) = @_;
    my $verb = $msg->{verb};
    if( $verb eq 'joined' || $verb eq 'renamed to' ) {
        $meta->set_client( $msg->{address} , $msg );
    }
    elsif( $verb eq 'leaved' ) {
        $meta->remove_client( $msg->{address} );
    }

    if( $verb eq 'joined' 
        || $verb eq 'leaved'
        || $verb eq 'renamed to'
    ) {
        my $list = $meta->get_client_list();
        $topic->publish({
            type => 'client_list',
            clientlist => $list,
        });
    }
}


my $msg_builder = WireRoom::Message::Builder->new;

# $msg_builder->set_builder('client_list', sub { return $_[1]; });
# $msg_builder->set_builder('action', sub { return $_[1]; });
# $msg_builder->set_builder('git', sub { return $_[1]; });

$msg_builder->set_builder('github', sub {
    my ($builder,$msg) = @_;
    return $msg;
});
$msg_builder->set_builder('says', sub {  
    my ($builder,$msg) = @_;
    return $builder->build_says($msg);
});


builder {
    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } "Plack::Middleware::ReverseProxy";

    mount "/logs" => builder {
        return Plack::App::Directory->new({ root => $log_root })->to_app;
    };

    mount "/server-status" => Web::ApacheStatus->new( 
                    url => 'http://corneltek.com/server-status',
                    extended => 1 );

    if( $config->{backend}{plugins}{Jenkins} ) {
        mount "/jenkins/hook" => builder {
            enable "+Web::JenkinsNotification";
            return sub {
                my $env = shift;
                my $notification = $env->{'jenkins.notification'};
                my $request = Plack::Request->new($env);

                if( $notification->phase !~ m/completed/i && $notification !~ m/started/i ) {
                    return;
                }
                my $payload = $notification->to_hashref;
                $payload->{type} = 'jenkins.notification';
                $payload = $msg_builder->build_with_request( $payload , $request );
                $topic->publish($payload);

                my $response = Plack::Response->new(200);
                $response->body( '{ "success": 1 }' );
                return $response->finalize;
            };
        };
    }

    if( $config->{backend}{plugins}{GitHub} ) {
        mount "/github/hook" => builder {
            sub {
                my $env = shift;
                my $req = Plack::Request->new($env);
                my $res = Plack::Response->new(200);

                # parse payload
                my $payload = GitHub::PostReceive->new( $req->param('payload') );

                unless( $payload->validate ) {
                    $res->status(403);
                    $res->body( encode_json { error => 1 } );
                    return $res->finalize;
                }

                my $msg = $payload->to_hashref;
                $msg->{type} = 'github';

                $msg = $msg_builder->build_with_request( $msg , $req );
                $topic->publish($msg);

                $res->body( encode_json { success => 1 } );
                return $res->finalize;
            };
        };
    }

    ## XXX: make a github hook
    mount "/api/message" => builder {
        sub {
            my $env      = shift;
            my $req      = Plack::Request->new($env);
            my $body     = $req->content;
            return [ 403 , [ 'Content-Type' => 'text/plain' ] 
                    , ['Empty body'] ] unless $body;

            return [ 403 , [ 'Content-Type' => 'text/plain' ]
                    , ['Message content is too long'] ] if length $body > 1024 * 5; # 5kb limit

            # forgot this
            # return [ 200 , [ 'Content-Type' => 'text/plain' ] , [ '' ] ];

            my $msg      = decode_json( $body );

            # XXX: verify messager and message here
            my $res = Plack::Response->new(200);
            if( $msg ) {
                $topic->publish($msg);
                $res->body(encode_json({ success => 1 }));
            }
            else {
                $res->status(403);
                $res->body(encode_json {error => 1});
            }
            return $res->finalize;
        };
    };

    mount "/_hippie/" => builder {
        enable "+Web::Hippie";
        enable "+Web::Hippie::Pipe", bus => $bus;
        sub {
            my $env = shift;
            my $request = Plack::Request->new($env);

            my $room = $env->{'hippie.args'};

            # warn $env->{PATH_INFO};

            my $topic = $env->{'hippie.bus'}->topic($room);
            if ($env->{PATH_INFO} eq '/new_listener') 
            {
                $env->{'hippie.listener'}->subscribe( $topic );
            }
            elsif ($env->{PATH_INFO} eq '/message') 
            {
                my $msg = $env->{'hippie.message'};

                # repack message
                $msg = $msg_builder->build_with_request( $msg , $request );

                # this triggers namelist
                dispatch_verb($topic,$msg) if defined $msg->{verb};

                if( $msg->{type} ne 'ping' ) {
                    $topic->publish($msg);
                }
            }
            else {
                my $h = $env->{'hippie.handle'}
                    or return [ '400', [ 'Content-Type' => 'text/plain' ], [ "Hippie Empty" ] ];

                if ($env->{PATH_INFO} eq '/error') {
                    warn "==> disconnecting $h";
                }
                else {
                    die "unknown hippie message";
                }
            }
            return [ '200', [ 'Content-Type' => 'application/hippie' ], [ "" ] ]
        };
    };

#     mount '/static' =>
#         Plack::App::Cascade->new
#                 ( apps => [ Web::Hippie::App::JSFiles->new->to_app,
#                             Plack::App::File->new( root => 'static' )->to_app,
#                         ]);

    mount "/" => builder {

        # XXX: When in development mode, do not mount authentication
        enable "Auth::Basic", authenticator => sub {
            my($username, $password) = @_;
            return $username eq $config->{backend}{auth}{username}
                && $password eq $config->{backend}{auth}{password};
        };
        enable "Static", path => qr{^/(test|pages|logs|images|js|css)/}, root => 'public/';
        enable "Session::Cookie";
        enable "Session";


        sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $res = $req->new_response(200);
            my $html = $tx->render( 'index.html' , { 
                env => $ENV{PLACK_ENV}
            });

            $res->body( encode_utf8 $html );
            return $res->finalize;
        }
    };
};
