package REE::RE::Sequence;
use REE::Mo 'required';
extends 'REE::RE';

use REE::RE::Nothing;

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

    # no regex: nothing
    return REE::RE::Nothing->new unless @{$self->res};

    # only one re: no sequence
    return $self->res->[0]->simplified if @{$self->res} == 1;

    # simplify all sub-regexes
    $self->res([map $_->simplified => @{$self->res}]);
    return $self;
}

sub compile {
    my $self = shift;

    # shortcut
    return unless @{$self->res};

    # list helper (NFA sequence is a pairwise operation)
    return $self->_compile_list(@{$self->res});
}

sub _compile_list {
    my ($self, @rest) = @_;
    my $first = shift @rest;

    # only one sub regex
    return $first->compile unless @rest;

    # more than one: append compiled rest
    return $first->compile->append($self->_compile_list(@rest));
}
