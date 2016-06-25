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

sub simplified {
    my $self = shift;

    # only one re: no alternation
    return $self->res->[0]->simplified if @{$self->res} == 1;

    # simplify all sub-regexes
    $self->res([map $_->simplified => @{$self->res}]);
    return $self;
}

sub compile {
    my $self = shift;

    # shortcut
    return unless @{$self->res};

    # list helper (NFA alternation is a pairwise operation)
    return $self->_compile_list(@{$self->res});
}

sub _compile_list {
    my ($self, @rest) = @_;
    my $first = shift @rest;

    # only one sub regex
    return $first->compile unless @rest;

    # more than one: alternate first with compilation of rest
    return $first->compile->alternate($self->_compile_list(@rest));
}
