package REE::NFA;
use REE::Mo qw(default builder);

has name            => 'unnamed NFA';
has states          => (builder => '_init_states');
has _state_counter  => 1;
has state           => sub {shift->get_start};
has _final          => {};

sub _init_states {
    shift->states(['q_0']);
}

sub get_start {
    my $self = shift;
    return $self->states->[0]; # first = start
}

sub is_start {
    my ($self, $state) = @_;
    return $state eq $self->get_start;
}

sub set_final {
    my ($self, $state) = @_;
    $self->_final->{$state} = 1;
}

sub unset_final {
    my ($self, $state) = @_;
    $self->_final->{$state} = '';
}

sub is_final {
    my ($self, $state) = @_;
    return $self->_final->{$state};
}

sub is_done {
    my $self = shift;
    return $self->is_final($self->state);
}

1;
__END__
