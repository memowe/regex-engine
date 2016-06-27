package REE;
use REE::Mo qw(required is default build);

use strict;
use warnings;

use REE::Parser;

our $VERSION = '0.01';

has regex   => (required => 1, is => 'ro');
has parser  => sub {REE::Parser->new};
has '_re';
has '_nfa';

sub BUILD {
    my $self = shift;

    # parse
    eval {$self->_re($self->parser->parse($self->regex))};
    die "Parse error: $@" if $@;

    # compile
    $self->_nfa($self->_re->compile);
}

sub match {
    my ($self, $input) = @_;

    # try to match
    eval {$self->_nfa->init->consume_string($input)};

    # illegal input
    return if $@ =~ /^illegal input/;

    # automaton not in final state
    return unless $self->_nfa->is_done;

    # automaton in final state: success
    return 1;
}

sub canonical_regex {
    my $self = shift;
    return $self->_re->to_regex;
}

sub nfa_representation {
    my $self = shift;
    return $self->_nfa->init->to_string;
}

1;
