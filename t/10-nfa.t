#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Test::More tests => 30;

use_ok 'REE::NFA';

# prepare noname dfa
my $noname = REE::NFA->new;
isa_ok $noname, 'REE::NFA';
is $noname->name, 'unnamed NFA', 'right default name';

# prepare trivial dfa
my $trivial = REE::NFA->new(name => 'trivial');
isa_ok $trivial, 'REE::NFA';
is $trivial->name, 'trivial', 'right name';
my $trivial_start = $trivial->start;
ok $trivial->is_start($trivial_start), 'start state known as start state';
is $trivial_start, 'q_000', 'right start state name';
is $trivial_start, $trivial->state, 'current state is start state';

# illegal input to trivial dfa
my $trivial_before = $trivial->state;
eval {$trivial->consume('a')};
like $@, qr/^illegal input: 'a'/, 'illegal input denied';
is $trivial->state, $trivial_before, 'input denial: no state transition';

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
eval {$a_acceptor->consume('z')};
like $@, qr/^illegal input: 'z'/, 'transition not known yet';
$a_acceptor->add_transitions($a_acceptor_start => {z => $a_acceptor_end});
$a_acceptor->consume('z');
is $a_acceptor->state, $a_acceptor_end, 'right state after transition';
ok $a_acceptor->is_done, 'input accepted';
$a_acceptor->rewind;
is $a_acceptor->state, $a_acceptor->start, 'rewind successful';
$a_acceptor->consume('z');
ok $a_acceptor->is_done, 'same input accepted again';

# trivial nfa
ok ! $trivial->is_done, 'start state is not final';
$trivial->set_final($trivial_start);
ok $trivial->is_final($trivial_start), 'start state set to final';
ok $trivial->is_done, 'start state is final';
$trivial->consume($REE::NFA::eps);
ok $trivial->is_final($trivial->current_state), 'state is still final';
ok $trivial->is_done, 'state is still final';
is $trivial_start, $trivial->state, 'no transition';
$trivial->unset_final($trivial_start);
ok $trivial->is_final($trivial_start), 'start state set to not final';
ok ! $trivial->is_done, 'start state is not final again';
