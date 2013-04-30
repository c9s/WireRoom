package WireRoom::Message;
use Moose;
use methods-invoker;
use LWP::UserAgent;
use HTTP::Request::Common;
use Git::Hook::PostReceive;
use JSON;

has type =>
    is => 'rw',
    isa => 'Str';

has payload =>
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{  } };

has client =>
    is => 'rw';
    # isa => 'Str';

has address =>
    is => 'rw';

has room =>
    is => 'rw';

has timestamp =>
    is => 'rw',
    default => sub { time };

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if( ref $_[0] ) {
        my $hashref = $_[0];
        my %args = (
            (map { $_ => delete($hashref->{$_}) } grep { defined $hashref->{$_} } qw(type client address timestamp)),
            payload => $hashref,
        );
        return $class->$orig( %args );
    }
    return $class->$orig( @_ );
};

method build_request (%options) {
    die 'options is required' unless %options;
    my $post_url = $options{url};
    
    unless ($post_url) {
        die 'host is require' unless $options{host};
        $post_url = 'http://'.$options{host};
        $post_url .= ':' . $options{port} if $options{port};
        $post_url .= '/api/message';
    }

    my $request = HTTP::Request->new(POST => $post_url);
    my $hashref = $->to_hashref;

    my $json = JSON->new->allow_blessed->convert_blessed->encode( $hashref );
    $request->header('Content-Type' => 'application/json');
    $request->content( $json );

    if( $options{basic_auth} ) {
        $request->authorization_basic( $options{basic_auth}->{user} , $options{basic_auth}->{pass} );
    }
    return $request;
};

method submit (%options) {
    my $request = $->build_request( %options );
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    return $ua->request($request);
}

method to_hashref {
    my $msg = $->payload;
    map { $msg->{ $_ } = $->$_ } qw(type client address timestamp room);
    return $msg;
};

__PACKAGE__->meta->make_immutable;
1;
__END__

=head3 message types

    - says
    - action
    - data

=head3 Message from http client

    {
        'client': WireRoom.IDENTIFIER, 
        type: 'says', 
        html:  b, 
        nickname: info.name,
        avatar: info.avatar,
        email: info.email
    }

=head3 Built text/html message

    {
        ... extends from message
        time: (timestamp),
        address: IP address
    }

=cut

