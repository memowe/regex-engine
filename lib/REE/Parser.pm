package REE::Parser;
use REE::Mo;
use REE::RE::Alternation;
use REE::RE::Sequence;
use REE::RE::Repetition;
use REE::RE::Literal;

has _input => undef;

sub _next_char {
    my $self = shift;

    # extract first character
    my $input = $self->_input;
    my $first = substr $input, 0, 1;
    return unless length $first == 1;

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

    # parse sequences
    my @sequences = (REE::RE::Sequence->new(res => []));
    while (defined(my $c = $self->_next_char)) {
        my $buffer;

        # new alternative
        if ($c eq '|') {
            push @sequences, REE::RE::Sequence->new(res => []);
        }

        # sub-alternation
        elsif ($c eq '(') {
            $buffer = $self->parse_alternation;
        }

        # alternation finished
        elsif ($c eq ')') {
            last;
        }

        # repetition of previous re
        elsif ($c eq '*') {

            # get previous re
            my $cur_seq = $sequences[-1];
            die "unexpected *\n" unless $cur_seq;
            my $cur_re  = pop @{$cur_seq->res};
            die "unexpected *\n" unless $cur_re;

            # inject repeated re
            push @{$cur_seq->res}, REE::RE::Repetition->new(re => $cur_re);
        }

        # literal
        else {
            $buffer = REE::RE::Literal->new(value => $c);
        }

        # add buffer to last sequence
        if (defined $buffer) {
            my $current = $sequences[-1];
            push @{$current->res}, $buffer;
        }
    }

    # collect sequences
    return REE::RE::Alternation->new(res => \@sequences)->simplified;
}
