#!/usr/bin/env perl

use strict;
use warnings;
use experimental 'smartmatch';
use utf8;

use Test::More tests => 54;

use_ok 'REE::NFA';

# prepare noname dfa
my $noname = REE::NFA->new;
isa_ok $noname, 'REE::NFA';
is $noname->name, 'unnamed NFA', 'right default name';
is $noname->to_string, <<"END", 'right stringification';
unnamed NFA:
* q_0 (start):
END
is "$noname", $noname->to_string, 'consistent stringification';

# prepare trivial dfa
my $trivial = REE::NFA->new(name => 'trivial');
isa_ok $trivial, 'REE::NFA';
is $trivial->name, 'trivial', 'right name';
my $trivial_start = $trivial->start;
ok $trivial->is_start($trivial_start), 'start state known as start state';
is $trivial_start, 'q_0', 'right start state name';
is $trivial_start, $trivial->current_state, 'current state is start state';

# illegal input to trivial dfa
my $trivial_before = $trivial->current_state;
eval {$trivial->consume('a'); fail("didn't die of illegal input")};
like $@, qr/^illegal input: 'a'/, 'illegal input denied';
is $trivial->current_state, $trivial_before, 'illegal input: no transition';

# prepare single character acceptor
my $a_acceptor = REE::NFA->new(name => 'z acceptor');
isa_ok $a_acceptor, 'REE::NFA';
is $a_acceptor->name, 'z acceptor', 'right name';
my $a_acceptor_start = $a_acceptor->start;
my $a_acceptor_end   = $a_acceptor->new_state;
like $a_acceptor_start, qr/^q_(\d+)$/, 'right start state name';
like $a_acceptor_end, qr/^q_(\d+)$/, 'right final state name';
isnt $a_acceptor_start, $a_acceptor_end, 'start and final state different';
ok ! $a_acceptor->is_final($a_acceptor_start), 'start not final';
ok ! $a_acceptor->is_final($a_acceptor_end), 'end not final';
$a_acceptor->set_final($a_acceptor_end);
ok $a_acceptor->is_final($a_acceptor_end), 'end is final';
is $a_acceptor->to_string, <<"END", 'right stringification';
z acceptor:
* $a_acceptor_start (start):
$a_acceptor_end (final):
END
is "$a_acceptor", $a_acceptor->to_string, 'consistent stringification';
eval {$a_acceptor->consume('z'); fail("didn't die of illegal input")};
like $@, qr/^illegal input: 'z'/, 'transition not known yet';
$a_acceptor->add_transitions($a_acceptor_start => {z => $a_acceptor_end});
is $a_acceptor->to_string, <<"END", 'right stringification';
z acceptor:
* $a_acceptor_start (start):
    z -> $a_acceptor_end
$a_acceptor_end (final):
END
is "$a_acceptor", $a_acceptor->to_string, 'consistent stringification';
$a_acceptor->consume('z');
is $a_acceptor->current_state, $a_acceptor_end, 'right state after transition';
ok $a_acceptor->is_done, 'input accepted';
$a_acceptor->init;
is $a_acceptor->current_state, $a_acceptor->start, 'rewind successful';
$a_acceptor->consume('z');
ok $a_acceptor->is_done, 'same input accepted again';

# non-trivial dfa: /^[ab]*cd+$/
my $abcd = REE::NFA->new(name => 'abcd sth acceptor');
my $abcd_start = $abcd->start;
my $abcd_got_c = $abcd->new_state;
my $abcd_got_d = $abcd->new_state;
$abcd->set_final($abcd_got_d);
$abcd->add_transitions($abcd_start => {
    a => $abcd_start,
    b => $abcd_start,
    c => $abcd_got_c,
});
$abcd->add_transitions($abcd_got_c => {
    d => $abcd_got_d,
});
$abcd->add_transitions($abcd_got_d => {
    d => $abcd_got_d,
});
is $abcd->to_string, <<"END", 'created the right automaton';
abcd sth acceptor:
* $abcd_start (start):
    a -> $abcd_start
    b -> $abcd_start
    c -> $abcd_got_c
$abcd_got_c:
    d -> $abcd_got_d
$abcd_got_d (final):
    d -> $abcd_got_d
END
$abcd->consume_string('cd');
ok $abcd->is_done, '"cd" consumed successfully';
$abcd->init;
$abcd->consume_string('ababcd');
ok $abcd->is_done, '"ababcd" consumed successfully';
$abcd->init;
$abcd->consume_string('aaacd');
ok $abcd->is_done, '"aaacd" consumed successfully';
$abcd->init;
$abcd->consume_string('cddd');
ok $abcd->is_done, '"cddd" consumed successfully';
$abcd->init;
$abcd->consume_string('bbbabbaaabacdd');
ok $abcd->is_done, '"bbbabbaaabacdd" consumed successfully';
$abcd->init;
$abcd->consume_string('');
ok ! $abcd->is_done, 'not done (substring)';
$abcd->consume('c');
ok ! $abcd->is_done, 'not done (substring)';
$abcd->consume_string('ddd');
ok $abcd->is_done, 'done consuming step by step';
$abcd->consume('d');
ok $abcd->is_done, 'done consuming legal input after final';
$abcd->init;
eval {$abcd->consume('d'); fail("didn't die of illegal input")};
like $@, qr/^illegal input: 'd'/, 'final input illegal at the beginning';
$abcd->consume('c')->consume('d');
ok $abcd->is_done, 'continued parsing of a valid sequence after exception';

# trivial nfa
my $nfa = REE::NFA->new(name => 'trivial nfa');
my $nfa_start   = $nfa->start;
my $nfa_end     = $nfa->new_state;
$nfa->set_final($nfa_end);
$nfa->add_transitions($nfa_start => {a => [$nfa_start, $nfa_end]});
is "$nfa", <<"END", 'created the right automaton';
trivial nfa:
* $nfa_start (start):
    a -> $nfa_start, $nfa_end
$nfa_end (final):
END
is $nfa->current_state, $nfa_start, 'right start state';
$nfa->consume('a');
my @states = $nfa->current_states;
is scalar @states, 2, 'nfa is in two states at the same time';
ok $nfa_start ~~ @states, 'start state is current';
ok $nfa_end ~~ @states, 'end state is current';
ok $nfa->is_done, 'one state is final';
is "$nfa", <<"END", 'right finalized nfa';
trivial nfa:
* $nfa_start (start):
    a -> $nfa_start, $nfa_end
* $nfa_end (final):
END

# trivial ε-nfa
my $enfa = REE::NFA->new(name => 'trivial ε-nfa');
my $enfa_start = $enfa->start;
my $enfa_next  = $enfa->new_state;
my $enfa_final = $enfa->new_state;
$enfa->set_final($enfa_final);
$enfa->add_transitions($enfa_start => {
    a               => $enfa_next,
    $REE::NFA::eps  => $enfa_next,
});
$enfa->add_transitions($enfa_next => {a => $enfa_final});
is "$enfa", <<"END", 'right enfa';
trivial ε-nfa:
* $enfa_start (start):
    ε -> $enfa_next
    a -> $enfa_next
$enfa_next:
    a -> $enfa_final
$enfa_final (final):
END
$enfa->consume_string('a');
ok $enfa->is_done, 'enfa-parsed a string successfully';
@states = $enfa->current_states;
is scalar @states, 2, 'enfa is in two states at the same time';
ok $enfa_next ~~ @states, 'intermediate state is current';
ok $enfa_final ~~ @states, 'final state is current';
is "$enfa", <<"END", 'right multi-current stringification';
trivial ε-nfa:
$enfa_start (start):
    ε -> $enfa_next
    a -> $enfa_next
* $enfa_next:
    a -> $enfa_final
* $enfa_final (final):
END
