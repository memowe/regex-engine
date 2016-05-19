package REE::RE::Literal;
use REE::Mo 'required';
extends 'REE::RE';

has value => (required => 1);

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';
    return $indent . 'LITERAL: "' . quotemeta($self->value) . '"';
}
