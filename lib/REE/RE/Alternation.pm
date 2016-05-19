package REE::RE::Alternation;
use REE::Mo 'required';
extends 'REE::RE';

has res => (required => 1);

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';

    my $output = $indent . "ALTERNATION: (\n";
    $output .= $_->to_string("$indent    ") for @{$self->res};
    $output .= $indent . ")\n";

    return $output;
}

sub to_regex {
    my $self = shift;
    my $combined = join '|' => map $_->to_regex => @{$self->res};
    return "($combined)";
}
