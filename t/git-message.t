#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 4;
use Plack::Test;
use Git::Hook::PostReceive;
use WireRoom::Message;
use HTTP::Request;

my $payload = Git::Hook::PostReceive->new->run( 
    'e4e8fe273036dc1af25c767143db3e98933cfed6',
    '7f8473022487a40eb81d0100ae3399a434c6247c',
    'refs/heads/master'
);

ok $payload;
ok $payload->{commits};

my $msg = WireRoom::Message->new( 
	type => 'git',
	payload => $payload,
);
ok $msg;

# http://advent.plackperl.org/2009/12/day-13-use-placktest-to-test-your-application.html

my $app = require 'app.psgi';
test_psgi $app, sub {
	my $cb = shift;
	my $req = $msg->build_request( 
		host => 'localhost',
 		basic_auth => { user => 'admin' , pass => 's3cr3t' },
	);
	my $res = $cb->( $req );
	ok $res;
};

1;
