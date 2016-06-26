#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 45;

use REE::RE::Literal;
use REE::RE::Repetition;
use REE::RE::Alternation;
use REE::RE::Sequence;
use REE::Parser;

# how a literal acceptor should look like
my $literal_acceptor_rx = qr/^[^:]*:
\* (\S+) \(start\):
    (.) -> (\S+)
\3 \(final\):
$/;

# test some literals
my $lit_a = REE::RE::Literal->new(value => 'a');
my $lit_a_nfa = $lit_a->compile();
isa_ok $lit_a_nfa, 'REE::NFA', 'got an automaton';
ok ! $lit_a_nfa->is_done, 'literal acceptor not done';
$lit_a_nfa->consume('a');
ok $lit_a_nfa->is_done, 'a literal accepted';
eval {$lit_a_nfa->consume('a'); fail("didn't die")};
like $@, qr/^illegal input: 'a'/, 'consuming a literal again is illegal';
$lit_a_nfa->init;
ok "$lit_a_nfa" =~ $literal_acceptor_rx, 'right literal acceptor';
isnt $1, $3, 'two different states';
is $2, 'a', 'accepts only one a input';

my $lit_snow = REE::RE::Literal->new(value => '❤');
my $lit_snow_nfa = $lit_snow->compile();
isa_ok $lit_snow_nfa, 'REE::NFA', 'got an automaton';
ok ! $lit_snow_nfa->is_done, 'literal acceptor not done';
$lit_snow_nfa->consume('❤');
ok $lit_snow_nfa->is_done, 'heart literal accepted';
eval {$lit_snow_nfa->consume('❤'); fail("didn't die")};
like $@, qr/^illegal input:.*❤/, 'consuming heart literal again is illegal';
$lit_snow_nfa->init;
ok "$lit_snow_nfa" =~ $literal_acceptor_rx, 'right literal acceptor';
isnt $1, $3, 'two different states';
is $2, '❤', 'accepts only one heart input';

# how a repetition of a literal acceptor should look like
my $repetition_acceptor_rx = qr/^[^:]*:
\* (\S+) \(start, final\):
    (.) -> (\S+)
\3 \(final\):
    ε -> \1
$/;

# test a repetition
my $rep = REE::RE::Repetition->new(re => REE::RE::Literal->new(value => 'a'));
my $rep_nfa = $rep->compile();
isa_ok $rep_nfa, 'REE::NFA', 'got an automaton';
ok $rep_nfa->is_done, 'empty word accepted';
$rep_nfa->consume('a');
ok $rep_nfa->is_done, 'a accepted';
$rep_nfa->consume('a');
ok $rep_nfa->is_done, 'aa accepted';
$rep_nfa->consume('a');
ok $rep_nfa->is_done, 'aaa accepted';
eval {$rep_nfa->consume('b'); fail("didn't die")};
$rep_nfa->init;
like $@, qr/^illegal input: 'b'/, 'consuming b is illegal';
ok "$rep_nfa" =~ $repetition_acceptor_rx, 'right repetition acceptor';
isnt $1, $3, 'two different states';
is $2, 'a', 'accepts only a';

# how an alternation of two literal acceptors should look like
my $alternation_acceptor_rx = qr/^[^:]*:
\* \S+ \(start\):
    ε -> (\S+), (\S+)
\* \1:
    (.) -> (\S+)
\4 \(final\):
\* \2:
    (.) -> (\S+)
\6 \(final\):
$/;

# test an alternation
my $alt = REE::RE::Alternation->new(res => [
    REE::RE::Literal->new(value => 'a'),
    REE::RE::Literal->new(value => 'b'),
]);
my $alt_nfa = $alt->compile();
isa_ok $alt_nfa, 'REE::NFA', 'got an automaton';
ok ! $alt_nfa->is_done, 'alternation acceptor not done';
$alt_nfa->consume('a');
ok $alt_nfa->is_done, 'a accepted';
$alt_nfa->init;
$alt_nfa->consume('b');
ok $alt_nfa->is_done, 'b accepted';
$alt_nfa->init;
ok "$alt_nfa" =~ $alternation_acceptor_rx, 'right alternation acceptor';
is $3, 'a', 'right input';
is $5, 'b', 'right input';

# how a sequence of two literal acceptors should look like
my $sequence_acceptor_rx = qr/^[^:]*:
\* \S+ \(start\):
    (.) -> (\S+)
\2:
    ε -> (\S+)
\3:
    (.) -> (\S+)
\5 \(final\):
$/;

# test a sequence
my $seq = REE::RE::Sequence->new(res => [
    REE::RE::Literal->new(value => 'a'),
    REE::RE::Literal->new(value => 'b'),
]);
my $seq_nfa = $seq->compile();
isa_ok $seq_nfa, 'REE::NFA', 'got an automaton';
ok ! $seq_nfa->is_done, 'sequence acceptor not done';
$seq_nfa->consume('a');
ok ! $seq_nfa->is_done, 'sequence acceptor not done after consuming "a"';
$seq_nfa->consume('b');
ok $seq_nfa->is_done, 'sequence acceptor done after consuming "b"';
$seq_nfa->init;
ok "$seq_nfa" =~ $sequence_acceptor_rx, 'right sequence acceptor';
is $1, 'a', 'right input';
is $4, 'b', 'right input';

# compile complex nested regex
my $complex_nfa = REE::Parser->new->parse('a(b|cd*)*e|f*g')->compile;
ok ! $complex_nfa->is_done, 'complex nfa not done';
$complex_nfa->consume_string('g');
ok $complex_nfa->is_done, 'input "g" accepted';
$complex_nfa->init->consume_string('ffffg');
ok $complex_nfa->is_done, 'input "ffffg" accepted';
$complex_nfa->init->consume_string('ffff');
ok ! $complex_nfa->is_done, 'input "ffff" not accepted';
$complex_nfa->init->consume_string('ae');
ok $complex_nfa->is_done, 'input "ae" accepted';
$complex_nfa->init->consume_string('abcbce');
ok $complex_nfa->is_done, 'input "abcbce" accepted';
$complex_nfa->init->consume_string('abcbbcdddde');
ok $complex_nfa->is_done, 'input "abcbbcdddde" accepted';
eval {$complex_nfa->init->consume_string('abcbbcddddef'); fail("didn't die")};
like $@, qr/^illegal input: 'f'/, 'input "abcbbcddddef" not accepted';

__END__
