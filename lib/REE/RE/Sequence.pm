package REE::RE::Sequence;
use REE::Mo 'required';
extends 'REE::RE';

has res => (required => 1);

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';

    my $output = $indent . "SEQUENCE: (\n";
    $output .= $_->to_string("$indent    ") for @{$self->res};
    $output .= $indent . ")\n";

    return $output;
}

sub to_regex {
    my $self = shift;
    my $combined = join '' => map $_->to_regex => @{$self->res};
    return "($combined)";
}

sub simplified {
    my $self = shift;

    # only one re: no sequence
    return $self->res->[0]->simplified if @{$self->res} == 1;

    # simplify all sub-regexes
    $self->res([map $_->simplified => @{$self->res}]);
    return $self;
}
