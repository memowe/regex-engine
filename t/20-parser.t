#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 19;

use_ok('REE::Parser');

# prepare parser
my $parser = REE::Parser->new;

# parse empty expression
my $re = $parser->parse('');
is $re->to_string, <<END, 'empty regex';
SEQUENCE: (
)
END
is $re->to_regex, '()', 'empty regex regex';

# parse single literal
$re = $parser->parse('a');
is $re->to_string, <<END, 'single literal';
LITERAL: "a"
END
is $re->to_regex, 'a', 'single literal regex';

# parse simple sequence
$re = $parser->parse('ab');
is $re->to_string, <<END, 'simple sequence';
SEQUENCE: (
    LITERAL: "a"
    LITERAL: "b"
)
END
is $re->to_regex, '(ab)', 'simple sequence regex';

# parse simple alternation
$re = $parser->parse('a|b');
is $re->to_string, <<END, 'simple alternation';
ALTERNATION: (
    LITERAL: "a"
    LITERAL: "b"
)
END
is $re->to_regex, '(a|b)', 'simple alternation regex';

# parse simple repetition
$re = $parser->parse('a*');
is $re->to_string, <<END, 'simple repetition';
REPETITION:
    LITERAL: "a"
END
is $re->to_regex, 'a*', 'simple repetition regex';

# parse nested sequence
$re = $parser->parse('ab*(c|d)');
is $re->to_string, <<END, 'nested sequence';
SEQUENCE: (
    LITERAL: "a"
    REPETITION:
        LITERAL: "b"
    ALTERNATION: (
        LITERAL: "c"
        LITERAL: "d"
    )
)
END
is $re->to_regex, '(ab*(c|d))', 'nested sequence regex';

# parse nested alternation
$re = $parser->parse('a|bc|d*');
is $re->to_string, <<END, 'nested alternation';
ALTERNATION: (
    LITERAL: "a"
    SEQUENCE: (
        LITERAL: "b"
        LITERAL: "c"
    )
    REPETITION:
        LITERAL: "d"
)
END
is $re->to_regex, '(a|(bc)|d*)', 'nested alternation regex';

# parse nested repetition
$re = $parser->parse('(a|bc)*');
is $re->to_string, <<END, 'nested repetition';
REPETITION:
    ALTERNATION: (
        LITERAL: "a"
        SEQUENCE: (
            LITERAL: "b"
            LITERAL: "c"
        )
    )
END
is $re->to_regex, '(a|(bc))*', 'nested repetition regex';

# complex nested regex
$re = $parser->parse('a(b|cd*)*e|f*g');
is $re->to_string, <<END, 'complex nested';
ALTERNATION: (
    SEQUENCE: (
        LITERAL: "a"
        REPETITION:
            ALTERNATION: (
                LITERAL: "b"
                SEQUENCE: (
                    LITERAL: "c"
                    REPETITION:
                        LITERAL: "d"
                )
            )
        LITERAL: "e"
    )
    SEQUENCE: (
        REPETITION:
            LITERAL: "f"
        LITERAL: "g"
    )
)
END
is $re->to_regex, '((a(b|(cd*))*e)|(f*g))', 'complex nested regex';

__END__
