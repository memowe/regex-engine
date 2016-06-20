#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 17;

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
my $a_rep_start = $a_repetition->start;
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

# prepare alternation/sequence
my $a1 = REE::NFA->new(name => 'ab-acceptor');
my $a1_start    = $a1->start;
my $a1_next     = $a1->new_state;
my $a1_end      = $a1->new_state;
$a1->add_transition($a1_start, a => $a1_next);
$a1->add_transition($a1_next, b => $a1_end);
$a1->set_final($a1_end);
my $a2 = REE::NFA->new(name => 'cd-acceptor');
my $a2_start    = $a2->start;
my $a2_next     = $a2->new_state;
my $a2_end      = $a2->new_state;
$a2->add_transition($a2_start, c => $a2_next);
$a2->add_transition($a2_next, d => $a2_end);
$a2->set_final($a2_end);

# test alternation/sequence preparation
$a1->consume_string('ab');
ok $a1->is_done, 'consumed ab';
$a2->consume_string('cd');
ok $a2->is_done, 'consumed cd';

# test alternation
my $alternation = $a1->alternate($a2);
$alternation->consume_string('ab');
ok $alternation->is_done('consumed ab'), 'alternation consumed "ab"';
eval {$alternation->consume_string('cd'); fail("didn't die")};
like $@, qr/^illegal input: 'c'/, 'consuming "cd" now is illegal';
$alternation->init;
$alternation->consume_string('cd');
ok $alternation->is_done('consumed cd'), 'alternation consumed "cd"';
eval {$alternation->consume_string('ab'); fail("didn't die")};
like $@, qr/^illegal input: 'a'/, 'consuming "ab" now is illegal';

# test sequence
my $sequence = $a1->append($a2);
eval {$sequence->consume_string('cd'); fail("didn't die")};
like $@, qr/^illegal input: 'c'/, 'starting with "cd" is illegal';
$sequence->consume_string('ab');
eval {$sequence->consume_string('ab'); fail("didn't die")};
like $@, qr/^illegal input: 'a'/, 'appending "ab" to "ab" is illegal';
$sequence->consume_string('cd');
ok $sequence->is_done, 'sequence accepted';

__END__
