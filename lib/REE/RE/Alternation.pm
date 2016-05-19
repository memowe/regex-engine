package REE::RE::Alternation;
use REE::Mo 'required';

has res => (required => 1);

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';

    my $output = $indent . "ALTERNATION: (\n";
    $output .= $_->to_string("$indent    ") . "\n" for @{$self->res};
    $output .= $indent . ")";

    return $output;
}
