package REE::NFA;
use REE::Mo 'default';

use Carp;

our $eps = '#eps#';

has initialized => 0;
has name        => 'unnamed NFA';
has start       => sub {shift->_generate_state_name};
has _state_num  => -1;
has _states     => sub {+{shift->start => {
    final       => 0,
    current     => 1,
    transitions => {},
}}};

sub is_start {
    my ($self, $state) = @_;
    return $state eq $self->start;
}

sub all_states {
    my $self = shift;
    return keys %{$self->_states};
}

sub final_states {
    my $self = shift;
    return grep {$self->_states->{$_}{final}} keys %{$self->_states};
}

sub set_final {
    my ($self, $state) = @_;
    $self->_states->{$state}{final} = 1;
}

sub unset_final {
    my ($self, $state) = @_;
    $self->_states->{$state}{final} = 0;
}

sub is_final {
    my ($self, $state) = @_;
    return $self->_states->{$state}{final};
}

sub current_states {
    my $self = shift;
    return grep {$self->_states->{$_}{current}} keys %{$self->_states};
}

sub set_current {
    my ($self, $state) = @_;
    $self->_states->{$state}{current} = 1;
}

sub unset_current {
    my ($self, $state) = @_;
    $self->_states->{$state}{current} = 0;
}

sub no_current {
    my $self = shift;
    $self->unset_current($_) for $self->current_states;
}

sub is_current {
    my ($self, $state) = @_;
    return $self->_states->{$state}{current};
}

# DFA shorthand: returns a single value if only one current state
sub current_state {
    my $self = shift;
    my @current = $self->current_states;
    return $current[0] if @current == 1;
    return \@current;
}

sub is_done {
    my $self = shift;

    # check if one final state is current
    for my $final ($self->final_states) {
        return 1 if $self->is_current($final);
    }

    # nothing found
    return;
}

sub get_transitions {
    my ($self, $state) = @_;
    return %{$self->_states->{$state}{transitions}};
}

sub add_transitions {
    my ($self, $state, $trans) = @_;
    $self->_states->{$state}{transitions}{$_} = $trans->{$_} for keys %$trans;
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
    $self->_states->{$name} = {current => 0, final => 0, transitions => {}};
    return $name;
}

use overload '""' => \&to_string;
sub to_string {
    my $self = shift;
    my $output = $self->name . ":\n";

    # stringify states
    for my $state (sort keys %{$self->_states}) {
        $output .= $state;

        # state attributes
        my @attrs = (
            ($self->is_start($state) ? 'start' : ()),
            ($self->is_final($state) ? 'final' : ()),
        );
        $output .= ' (' . join(', ' => @attrs) . ')' if @attrs;

        # stringify transitions
        $output .= ":\n";
        my %next_state = %{$self->_states->{$state}{transitions}};
        $output .= "    $_ -> $next_state{$_}\n"
            for sort keys %next_state;
    }

    # done
    return $output;
}

sub init {
    my $self = shift;

    # set current = true iff start state
    $self->no_current;
    $self->set_current($self->start);

    # initial epsilon transitions
    $self->_eps_splits($self->start);

    # done
    $self->initialized(1);
}

sub _eps_splits {
    my ($self, $state) = @_;

    # nothing to do
    return if not $self->is_current($state)
        or not exists $self->_states->{$state}{transitions}{$eps};

    # epsilon transition available
    my $next = $self->_states->{$state}{transitions}{$eps};

    # next state already current
    return if $self->is_current($next);

    # epsilon transition
    $self->set_current($next);
    $self->_eps_splits($next);
}

sub consume {
    my ($self, $input) = @_;

    # initialized?
    $self->init unless $self->initialized;

    # prepare
    my @current = $self->current_states;
    $self->no_current;

    # try transitions on all states
    for my $state (@current) {
        my %transitions = $self->get_transitions($state);

        # no transition available here
        next unless exists $transitions{$input};

        # transition available
        my $next = $transitions{$input};
        $self->set_current($next);
        $self->_eps_splits($next);
    }

    # no transitions found: step back and complain
    unless ($self->current_states) {
        $self->set_current($_) for @current;
        croak "illegal input: '\Q$input\E'";
    }

    # allow chain call
    return $self;
}

sub consume_string {
    my ($self, $input) = @_;
    $self->consume($_) for split // => $input;
}

1;
__END__
