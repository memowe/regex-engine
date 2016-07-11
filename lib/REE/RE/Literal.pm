package REE::RE::Literal;
use REE::Mo 'required';
extends 'REE::RE';

use REE::NFA;

has value => (required => 1);

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';
    return $indent . 'LITERAL: "' . $self->value . '"' . "\n";
}

sub to_regex {
    my $self = shift;

    # escape special characters
    my @special = ('(', ')', '|', '*', '+', '[', ']');
    return '\\' . $self->value if grep {$_ eq $self->value} @special;

    # no escaping neccessary
    return $self->value;
}

sub compile {
    my $self = shift;

    # prepare NFA
    my $nfa = REE::NFA->new(name => $self->value . ' acceptor');
    my $nfa_start = $nfa->start;
    my $nfa_final = $nfa->new_state;

    # accept only one input
    $nfa->set_final($nfa_final);
    $nfa->add_transition($nfa_start => $self->value => $nfa_final);

    # done
    return $nfa;
}
