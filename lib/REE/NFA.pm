package REE::NFA;
use REE::Mo qw(default build);

use utf8;
use Carp;
use List::Util 'max';

our $eps = '#eps#';

has _initialized    => 0;
has _states         => {};
has name            => 'unnamed NFA';
has 'start';

sub BUILD {
    my $self = shift;
    $self->start($self->new_state);
    $self->set_current($self->start);
}

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
    return grep $self->_states->{$_}{final} => $self->all_states;
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
    return grep $self->_states->{$_}{current} => $self->all_states;
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

sub current_state {
    my $self = shift;
    my @current = $self->current_states;
    return $current[0] if @current == 1; # DFA shorthand
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

sub add_transition {
    my ($self, $state, $input, $next) = @_;

    # prepare state/transition data
    my $s = $self->_states->{$state};
    $s->{transitions}{$input} = [] unless defined $s->{transitions}{$input};
    my $t = $s->{transitions}{$input};

    # non-deterministic transition: unify, deterministic: append
    $next   = [$next] if ref $next ne 'ARRAY';
    @$t     = keys %{{ map {$_ => 1} @$t, @$next }};
}

sub add_transitions {
    my ($self, $state, $trans) = @_;
    $self->add_transition($state, $_, $trans->{$_}) for keys %$trans;
}

sub _max_state_index {
    my $self = shift;
    return -1 unless keys %{$self->_states}; # no states yet
    return max map {$_ =~ /(\d+)/; $1} keys %{$self->_states};
}

sub _generate_state_name {
    my $self = shift;
    return 'q_' . ($self->_max_state_index + 1);
}

sub new_state {
    my $self = shift;
    my $name = $self->_generate_state_name;
    $self->_states->{$name} = {current => 0, final => 0, transitions => {}};
    return $name;
}

use overload '""' => \&to_string;
sub to_string {
    my $self = shift;
    my $output = $self->name . ":\n";

    # stringify states (ordered by state number)
    my @state_names = keys %{$self->_states};
    my %state_num   = map {/(\d+)/; ($_ => $1)} @state_names;
    for my $state (sort {$state_num{$a} <=> $state_num{$b}} @state_names) {

        # current state marker
        $output .= '* ' if $self->is_current($state);
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
        for my $input (sort keys %next_state) {
            my $i = $input eq $eps ? 'ε' : $input;
            $output .= "    $i -> ";
            $output .= join(', ' => sort @{$next_state{$input} // []}) . "\n";
        }
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
    $self->_initialized(1);
}

sub _eps_splits {
    my ($self, $state) = @_;

    # nothing to do
    return if not $self->is_current($state)
        or not exists $self->_states->{$state}{transitions}{$eps};

    # epsilon transition available
    my @next_states = @{$self->_states->{$state}{transitions}{$eps}};

    # epsilon transitions
    for my $next (@next_states) {
        $self->set_current($next);
        $self->_eps_splits($next);
    }
}

sub consume {
    my ($self, $input) = @_;

    # initialized?
    $self->init unless $self->_initialized;

    # prepare
    my @current = $self->current_states;
    $self->no_current;

    # try transitions on all states
    for my $state (@current) {
        my %transitions = $self->get_transitions($state);

        # no transition available here
        next unless exists $transitions{$input};

        # transition available
        my @next_states = @{$transitions{$input}};
        for my $next (@next_states) {
            $self->set_current($next);
            $self->_eps_splits($next);
        }
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
