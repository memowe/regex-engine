#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 14;

use REE::RE::Literal;
use REE::RE::Repetition;
use REE::RE::Alternation;
use REE::RE::Sequence;

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
$lit_a_nfa->init;
like $@, qr/^illegal input: 'a'/, 'consuming a literal again is illegal';
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

__END__
