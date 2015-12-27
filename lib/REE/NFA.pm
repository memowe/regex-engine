package REE::NFA;
use REE::Mo qw(default builder);

has name            => 'unnamed NFA';
has states          => (builder => '_init_states');
has _state_counter  => 1;
has state           => sub {shift->get_start};

sub _init_states {
    shift->states(['q_0']);
}

sub get_start {
    my $self = shift;
    return $self->states->[0]; # first = start
}

sub is_start_state {
    my ($self, $state) = @_;
    return $state eq $self->get_start;
}

1;
__END__
