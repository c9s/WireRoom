#!/usr/bin/env perl
use lib 'lib';
use Test::More;
use Git::Hook::PostReceive;

my $payload = Git::Hook::PostReceive->new->run( 
    'e4e8fe273036dc1af25c767143db3e98933cfed6',
    '7f8473022487a40eb81d0100ae3399a434c6247c',
    'refs/heads/master'
);

ok $payload;
ok $payload->{commits};

for my $commit ( @{  $payload->{commits} } ) {
    ok $commit;
    ok $commit->{author}->{name};
    ok $commit->{author}->{email};
    ok $commit->{message};
    ok $commit->{date};
}

$payload = Git::Hook::PostReceive->new->read_stdin('e4e8fe273036dc1af25c767143db3e98933cfed6 7f8473022487a40eb81d0100ae3399a434c6247c refs/heads/master');
ok $payload , 'commit payload (diff)';
ok $payload->{commits} , 'commits';

$payload = Git::Hook::PostReceive->new->read_stdin('0000000000000000000000000000000000000000 7f8473022487a40eb81d0100ae3399a434c6247c refs/tags/0.01');
ok $payload, 'commit payload (new tag)';
ok $payload->{commits} , 'commits';
ok $payload->{new_head} , 'new head';
is $payload->{ref_type}, 'tags' , 'is tags';
done_testing;
