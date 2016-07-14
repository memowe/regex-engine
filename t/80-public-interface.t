#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 7;

use REE;

# illegal regex
eval {REE->new(regex => '*'); fail "didn't die"};
like $@, qr/^Parse error: unexpected */, 'died of regex parse error';

# regex matching
my $r = REE->new(regex => 'a(b|cd*|)+e|f*([gh]i)?');
ok $r->match('gi'), "'gi' matches";
ok ! $r->match('ffffh'), "'ffffh' doesn't match";
ok $r->match('abcbbcdddde'), "'abcbbcdddde' matches";
ok ! $r->match('abcbbcddddef'), "'abcbbcddddef' doesn't match";

# canonical regex
is $r->canonical_regex, '((a((b|(cd*)|)(b|(cd*)|)*)e)|(f*(|((g|h)i))))',
    'right canonical regex';

# nfa string representation
is $r->nfa_representation, <<END, 'right nfa string representation';
alternation of sequence of a acceptor and sequence of sequence of alternation of b acceptor and alternation of sequence of c acceptor and d acceptor and Nothing acceptor and alternation of b acceptor and alternation of sequence of c acceptor and d acceptor and Nothing acceptor and e acceptor and sequence of f acceptor and alternation of g acceptor and h acceptor:
* q_0 (start):
    ε -> q_1, q_23
* q_1:
    a -> q_2
q_2:
    ε -> q_3
q_3:
    ε -> q_4, q_6
q_4:
    b -> q_5
q_5:
    ε -> q_12
q_6:
    ε -> q_11, q_7
q_7:
    c -> q_8
q_8:
    ε -> q_9
q_9:
    ε -> q_12
    d -> q_10
q_10:
    ε -> q_12, q_9
q_11:
    ε -> q_12
q_12:
    ε -> q_13, q_15, q_21
q_13:
    b -> q_14
q_14:
    ε -> q_12, q_21
q_15:
    ε -> q_16, q_20
q_16:
    c -> q_17
q_17:
    ε -> q_18
q_18:
    ε -> q_12, q_21
    d -> q_19
q_19:
    ε -> q_12, q_18, q_21
q_20:
    ε -> q_12, q_21
q_21:
    e -> q_22
q_22 (final):
* q_23:
    ε -> q_25
    f -> q_24
q_24:
    ε -> q_23, q_25
* q_25:
    ε -> q_26, q_28
* q_26:
    g -> q_27
q_27 (final):
* q_28:
    h -> q_29
q_29 (final):
END

__END__
