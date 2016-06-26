package REE::RE;
use REE::Mo;

no warnings 'redefine';

sub to_string {
    my ($self, $indent) = @_;
    die "implement in subclass!\n";
}

sub to_regex {
    my $self = shift;
    die "implement in subclass!\n";
}

sub simplified {
    my $self = shift;
    return $self;
}

sub compile {
    my $self = shift;
    die "implement in subclass!\n";
}
