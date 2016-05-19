package REE::RE::Sequence;
use REE::Mo 'required';
extends 'REE::RE';

has res => (required => 1);

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';

    my $output = $indent . "SEQUENCE: (\n";
    $output .= $_->to_string("$indent    ") . "\n" for @{$self->res};
    $output .= $indent . ")";

    return $output;
}
