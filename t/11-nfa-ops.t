#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use REE::NFA;

# prepare repetition
my $a = REE::NFA->new(name => 'ab-acceptor');
my $a_start = $a->start;
my $a_next  = $a->new_state;
my $a_end   = $a->new_state;
$a->add_transition($a_start, a => $a_next);
$a->add_transition($a_next, b => $a_end);
$a->set_final($a_end);

# test repetition preparation
$a->consume_string('ab');
ok $a->is_done, 'consumed "ab"';
eval {$a->consume_string('ab'); fail("didn't die of illegal input")};
like $@, qr/^illegal input: 'a'/, 'consuming "ab" again is illegal';

# test repetition
my $a_repetition = $a->repetition;
my $a_rep_start = $a_repetition->get_start;
ok ! $a_repetition->is_done, 'a* ready for input';
$a_repetition->consume_string('ab');
ok $a_repetition->is_done, 'ab accepted';
$a_repetition->consume_string('ab');
ok $a_repetition->is_done, 'ab accepted again';
$a_repetition->consume_string('ab' x rand 17);
ok $a_repetition->is_done, 'more abs accepted';
ok $a_repetition->is_current($a_rep_start), 'again in start state';
$a_repetition->consume_string('a');
ok ! $a_repetition->is_done, 'not done after (ab)+a';

# TODO alternation

# TODO sequence

__END__
