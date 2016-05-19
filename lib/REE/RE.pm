package REE::RE;
use REE::Mo;

no warnings 'redefine';

sub to_string {
    my ($self, $indent) = @_;
    die "implement in subclass!\n";
}
