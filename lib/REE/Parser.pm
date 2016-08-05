package REE::Parser;
use REE::Mo;
use REE::RE::Nothing;
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

sub _push_back {
    my ($self, $char) = @_;
    $self->_input($char . $self->_input);
}

sub parse {
    my ($self, $input) = @_;
    $self->_input($input);
    return $self->_parse_alternation;
}

sub _parse_alternation {
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
            $buffer = $self->_parse_alternation;
        }

        # alternation finished
        elsif ($c eq ')') {
            last;
        }

        # repetitions
        elsif ($c eq '*' or $c eq '+' or $c eq '?') {

            # get previous re
            my $cur_seq = $sequences[-1]; # exists always
            my $cur_re  = pop @{$cur_seq->res};
            die "unexpected $c\n" unless $cur_re;

            # quantification
            my %re_options      = (re => $cur_re);
            $re_options{min}    = 1 if $c eq '+';
            $re_options{max}    = 1 if $c eq '?';

            # inject repeated re
            push @{$cur_seq->res}, REE::RE::Repetition->new(%re_options);
        }

        # character class
        # [abc] should be interpreted as (a|b|c)
        elsif ($c eq '[') {
            $buffer = $self->_parse_character_class;
        }

        # escaped literal
        elsif ($c eq '\\') {
            $buffer = $self->_parse_escaped_literal;
        }

        # lookahead for a literal
        else {
            $self->_push_back($c);
            $buffer = $self->_parse_literal;
        }

        # add buffer to last sequence
        if (defined $buffer) {
            my $current = $sequences[-1];
            push @{$current->res}, $buffer;
        }
    }

    # test for empty regex
    return REE::RE::Nothing->new unless @sequences;

    # collect sequences
    return REE::RE::Alternation->new(res => \@sequences)->simplified;
}

sub _parse_character_class {
    my $self = shift;

    # parse simple literals only (bypass escape checks)
    my @literals;
    while (defined(my $c = $self->_next_char)) {
        last if $c eq ']';

        # add to literals
        push @literals, REE::RE::Literal->new(value => $c);
    }

    # done
    return REE::RE::Alternation->new(res => \@literals);
}

sub _parse_literal {
    my $self = shift;
    my $next = $self->_next_char;

    # end of string
    return unless defined $next;

    # should've been escaped
    die "illegal literal: \"$next\"\n"
        if grep {$_ eq $next} @REE::RE::Literal::special_characters;

    # everything's fine
    return REE::RE::Literal->new(value => $next);
}

sub _parse_escaped_literal {
    my $self = shift;
    my $next = $self->_next_char;

    # end of string
    die "unexpected end of string\n" unless defined $next;

    # illegal escape sequence
    die "illegal escape sequence: \"\\$next\"\n"
        unless grep {$_ eq $next} @REE::RE::Literal::special_characters;

    # everything's fine
    return REE::RE::Literal->new(value => $next);
}
