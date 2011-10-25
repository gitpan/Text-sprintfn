#!perl -T

use 5.010;
use strict;
use warnings;

#use Data::Dump::OneLine qw(dump1);
use Test::More 0.96;
use Text::sprintfn;

test_sprintfn(
    name => "normal printf args",
    args => ['<%d> <%04x> <%1$6.2f>', 10, 17],
    res  => "<10> <0011> < 10.00>");

test_sprintfn(
    name => "sprintfn 1",
    args => ['<%(v1)03d> <%(v3)(v1)s> <%(v2)(v1).(v0)f>',
             {v1=>5, v2=>4, v3=>"foo", v0=>1}, 1, 2, 3],
    res  => "<005> <  foo> <  4.0>");

# XXX more tests

DONE_TESTING:
done_testing();

sub test_sprintfn {
    my (%args) = @_;

    my $test_name = $args{name} // "fmt $args{args}[0]";
    #subtest $test_name => sub {
        my $res = sprintfn(@{ $args{args} });
        is($res, $args{res}, "result");
    #};
}

