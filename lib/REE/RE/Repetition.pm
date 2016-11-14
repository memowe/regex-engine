package REE::RE::Repetition;
use REE::Mo qw(required default);
extends 'REE::RE';

use REE::RE::Sequence;
use REE::RE::Alternation;
use REE::RE::Nothing;

our $inf = 9**9**9;

has re  => (required => 1);
has min => 0;
has max => $inf;

sub max_str {
    my $c = shift;
    return $c->max == $inf ? 'oo' : $c->max;
}

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';

    my $output = $indent . 'REPETITION (';
    $output .= join ', ' => map {
        my $getter = $_ eq 'max' ? 'max_str' : $_;
        "$_: " . ($self->$getter // '')
    } qw(min max);
    $output .= "):\n";
    $output .= $self->re->to_string("$indent    ");
    return $output;
}

sub to_regex {
    my $self = shift;

    return $self->re->to_regex . (
          ($self->min == 0 and $self->max == $inf)  ? '*'
        : ($self->min == 1 and $self->max == $inf)  ? '+'
        : ($self->min == 0 and $self->max == 1)     ? '?'
        : ($self->max == $inf)                      ? ('{' . $self->min . ',}')
        : ($self->min == $self->max)                ? ('{' . $self->min . '}')
        : ('{' . $self->min . ',' . $self->max_str . '}')
    );
}

sub compile {
    my $self = shift;

    # star repetition
    if ($self->min == 0 and $self->max == $inf) {
        return $self->re->compile->repetition;
    }

    # plus repetition
    if ($self->min == 1 and $self->max == $inf) {
        return REE::RE::Sequence->new(res => [
            $self->re,
            REE::RE::Repetition->new(re => $self->re),
        ])->compile;
    }

    # optional quantification
    if ($self->min == 0 and $self->max == 1) {
        return REE::RE::Alternation->new(res => [
            REE::RE::Nothing->new,
            $self->re,
        ])->compile;
    }

    # prepare minimum/arbitrary quantification
    my $seq = REE::RE::Sequence->new;
    my $re  = $self->re;
    my $opt = REE::RE::Alternation->new(res => [REE::RE::Nothing->new, $re]);
    my $rep = REE::RE::Repetition->new(re => $re);

    # minimum quantification
    if ($self->max == $inf) {
        push @{$seq->res}, $re for 1 .. $self->min;
        push @{$seq->res}, $rep;
        return $seq->compile;
    }

    # arbitrary (finite) quantification
    push @{$seq->res}, $re  for 1 .. $self->min;
    push @{$seq->res}, $opt for $self->min + 1 .. $self->max;
    return $seq->compile;
}
