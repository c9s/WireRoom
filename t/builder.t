#!/usr/bin/env perl
use Test::More tests => 5;
use lib 'lib';
use WireRoom::Message::Builder;
use WireRoom::Message;

my $builder = WireRoom::Message::Builder->new;
ok $builder;

$builder->set_builder('says', sub {
		my $msg = shift;
		return $msg;
	});

my $msg = $builder->build({ type => 'says' , 'hack' => 1 });
ok $msg;

$msg = WireRoom::Message->new({  
		type => 'says',
		client => time,
		address => '127.0.0.1',
		body => "Body",
	});
ok $msg;
ok $msg->time;
ok $msg->address;
