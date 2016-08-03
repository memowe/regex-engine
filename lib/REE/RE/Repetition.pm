package REE::RE::Repetition;
use REE::Mo qw(required default);
extends 'REE::RE';

has re  => (required => 1);
has min => 0;
has max => 9**9**9; # infinity

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';

    my $output = $indent . 'REPETITION (';
    $output .= join ', ' => map {"$_: " . $self->$_} qw(min max);
    $output .= "):\n";
    $output .= $self->re->to_string("$indent    ");
    return $output;
}

sub to_regex {
    my $self = shift;

    return $self->re->to_regex . (
          ($self->min == 0 and $self->max == 9**9**9)   ? '*'
        : ($self->min == 1 and $self->max == 9**9**9)   ? '+'
        : ($self->min == 0 and $self->max == 1)         ? '?'
        : ($self->max == 9**9**9) ? ('{' . $self->min . ',}')
        : ('{' . $self->min . ',' . $self->max . '}')
    );
}

sub compile {
    my $self = shift;
    return $self->re->compile->repetition;
}
