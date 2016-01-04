package REE::NFA;
use REE::Mo 'default';

use Carp;

our $eps = '#eps#';

has name            => 'unnamed NFA';
has start           => sub {shift->_generate_state_name};
has _state_num      => -1;
has state           => sub {shift->start};
has _final          => {};
has _transitions    => sub {+{shift->start => {}}};

use overload '""' => \&to_string;

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

    # done
    $self->_transitions->{$name} //= {};
    return $name;
}

sub add_transitions {
    my ($self, $state, $trans) = @_;
    $self->_transitions->{$state}{$_} = $trans->{$_} for keys %$trans;
}

sub to_string {
    my $self = shift;
    my $output = $self->name . ":\n";

    # stringify states
    for my $state (sort keys %{$self->_transitions}) {
        $output .= $state;

        # state attributes
        my @attrs = (
            ($self->is_start($state) ? 'start' : ()),
            ($self->is_final($state) ? 'final' : ()),
        );
        $output .= ' (' . join(', ' => @attrs) . ')' if @attrs;

        # stringify transitions
        $output .= ":\n";
        my %next_state = %{$self->_transitions->{$state} // {}};
        $output .= "    $_ -> $next_state{$_}\n"
            for sort keys %next_state;
    }

    # done
    return $output;
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

    # allow chain call (useful for testing)
    return $self;
}

sub consume_string {
    my ($self, $input) = @_;
    $self->consume($_) for split // => $input;
}

1;
__END__
