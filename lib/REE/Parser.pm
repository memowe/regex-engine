package REE::Parser;
use REE::Mo;

has _input => undef;

sub _next_char {
    my $self = shift;

    # extract first character
    my $input = $self->_input;
    my $first = substr $input, 0, 1;

    # store remaining string
    $self->_input(substr $input, 1);

    # return first character
    return $first;
}

sub parse {
    my ($self, $input) = @_;
    $self->_input($input);
    return $self->parse_alternation;
}

sub parse_alternation {
    my $self = shift;

    my @sub_re_sequences = (REE::RE::Sequence->new(res => []));
    while (defined(my $c = $self->_next_char)) {
    }
}
