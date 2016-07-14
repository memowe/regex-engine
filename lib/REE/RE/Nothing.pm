package REE::RE::Nothing;
use REE::Mo;
extends 'REE::RE';

use REE::NFA;

sub to_string {
    my ($self, $indent) = @_;
    $indent //= '';
    return $indent . "NOTHING\n";
}

sub to_regex {''}

sub compile {
    my $self = shift;

    # prepare NFA
    my $done = REE::NFA->new(name => 'Nothing acceptor');

    # accepts nothing: is final from start and has no transitions
    my $done_start = $done->start;
    $done->set_final($done_start);

    # done
    return $done;
}
