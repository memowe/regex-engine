package REE::RE::Repetition;
use REE::Mo 'required';
extends 'REE::RE';

has re => (required => 1);

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';

    my $output = $indent . "REPETITION:\n";
    $output .= $self->re->to_string("$indent    ");
    return $output;
}

sub to_regex {
    my $self = shift;
    return $self->re->to_regex . '*';
}
