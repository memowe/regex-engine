package REE::NFA;
use REE::Mo 'default';

use Carp;

our $eps = '#eps#';

has name            => 'unnamed NFA';
has start           => 'q_000';
has _state_num      => 0;
has state           => sub {shift->start};
has _final          => {};
has _transitions    => {}; # HoH: {q_42 => {a => 'q_17', b => 'q_0'}}

sub rewind {
    my $self = shift;
    $self->state($self->start);
}

sub is_start {
    my ($self, $state) = @_;
    return $state eq $self->start;
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

sub _generate_state_name {
    my $self = shift;
    my $num  = $self->_state_num;
    my $name = 'q_' . sprintf '%03d' => ++$num;
    $self->_state_num($num);
    return $name;
}

sub new_state {
    my ($self, $name) = @_;

    # assign name
    $name //= $self->_generate_state_name;

    # not neccessary to remember that name since states are saved
    # implicitely via transitions
    return $name;
}

sub add_transitions {
    my ($self, $state, $trans) = @_;
    $self->_transitions->{$state}{$_} = $trans->{$_} for keys %$trans;
}

sub consume {
    my ($self, $input) = @_;

    # available transitions
    my %next_state = %{$self->_transitions->{$self->state} // {}};

    # illegal input?
    croak "illegal input: '\Q$input\E'"
        unless exists $next_state{$input};

    # input ok: update state
    $self->state($next_state{$input});
}

1;
__END__
