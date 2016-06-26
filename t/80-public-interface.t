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
my $r = REE->new(regex => 'a(b|cd*)*e|f*g');
ok $r->match('g'), "'g' matches";
ok ! $r->match('ffff'), "'ffff' doesn't match";
ok $r->match('abcbbcdddde'), "'abcbbcdddde' matches";
ok ! $r->match('abcbbcddddef'), "'abcbbcddddef' doesn't match";

# canonical regex
is $r->canonical_regex, '((a(b|(cd*))*e)|(f*g))', 'right canonical regex';

# nfa string representation
is $r->nfa_representation, <<END, 'right nfa string representation';
alternation of sequence of a acceptor and sequence of alternation of b acceptor and sequence of c acceptor and d acceptor and e acceptor and sequence of f acceptor and g acceptor:
* q_0 (start):
    ε -> q_1, q_12
* q_1:
    a -> q_2
q_2:
    ε -> q_3
q_3:
    ε -> q_10, q_4, q_6
q_4:
    b -> q_5
q_5:
    ε -> q_10, q_3
q_6:
    c -> q_7
q_7:
    ε -> q_8
q_8:
    ε -> q_10, q_3
    d -> q_9
q_9:
    ε -> q_10, q_3, q_8
q_10:
    e -> q_11
q_11 (final):
* q_12:
    ε -> q_14
    f -> q_13
q_13:
    ε -> q_12, q_14
* q_14:
    g -> q_15
q_15 (final):
END

__END__
