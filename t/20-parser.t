#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 44;

use_ok('REE::Parser');

# prepare parser
my $parser = REE::Parser->new;

# parse empty expression
my $re = $parser->parse('');
is $re->to_string, <<END, 'empty regex';
NOTHING
END
is $re->to_regex, '', 'empty regex regex';

# parse single literal
$re = $parser->parse('a');
is $re->to_string, <<END, 'single literal';
LITERAL: "a"
END
is $re->to_regex, 'a', 'single literal regex';

# parse illegal control sequence
eval {$parser->parse('*'); fail "didn't die"};
like $@, qr/^unexpected */, 'unexpected star';

# parse simple sequence
$re = $parser->parse('ab');
is $re->to_string, <<END, 'simple sequence';
SEQUENCE: (
    LITERAL: "a"
    LITERAL: "b"
)
END
is $re->to_regex, '(ab)', 'simple sequence regex';

# parse escaped special character literal
$re = $parser->parse('\\*');
is $re->to_string, <<END, 'single escape sequence';
LITERAL: "*"
END
is $re->to_regex, '\\*', 'single escape sequence regex';

# parse sequence with escaped special characters
$re = $parser->parse('a\\]b\\[c\\?d\\+e\\*f\\|g\\)h\\(i');
is $re->to_string, <<END, 'sequence with escaped special characters';
SEQUENCE: (
    LITERAL: "a"
    LITERAL: "]"
    LITERAL: "b"
    LITERAL: "["
    LITERAL: "c"
    LITERAL: "?"
    LITERAL: "d"
    LITERAL: "+"
    LITERAL: "e"
    LITERAL: "*"
    LITERAL: "f"
    LITERAL: "|"
    LITERAL: "g"
    LITERAL: ")"
    LITERAL: "h"
    LITERAL: "("
    LITERAL: "i"
)
END
is $re->to_regex, '(a\\]b\\[c\\?d\\+e\\*f\\|g\\)h\\(i)',
    'sequence with escaped special characters regex';

# parse illegal escape sequence: empty string
eval {$parser->parse('\\'); fail "didn't die"};
like $@, qr/^unexpected end of string/, 'illegal escape: end of string';

# parse illegal escape sequence: non-special character
eval {$parser->parse('\\a'); fail "didn't die"};
like $@, qr/^illegal escape sequence: "\\a"/, 'illegal escape sequence';

# parse simple alternation
$re = $parser->parse('a|b');
is $re->to_string, <<END, 'simple alternation';
ALTERNATION: (
    LITERAL: "a"
    LITERAL: "b"
)
END
is $re->to_regex, '(a|b)', 'simple alternation regex';

# parse half-empty alternation
$re = $parser->parse('|a');
is $re->to_string, <<END, 'half-empty alternation';
ALTERNATION: (
    NOTHING
    LITERAL: "a"
)
END
is $re->to_regex, '(|a)', 'half-empty alternation regex';

# parse multi empty alternation
$re = $parser->parse('|a|b||');
is $re->to_string, <<END, 'multi-empty alternation';
ALTERNATION: (
    NOTHING
    LITERAL: "a"
    LITERAL: "b"
    NOTHING
    NOTHING
)
END
is $re->to_regex, '(|a|b||)', 'multi-empty alternation regex';

# parse simple repetition
$re = $parser->parse('a*');
is $re->to_string, <<END, 'simple repetition';
REPETITION (min: 0, max: oo):
    LITERAL: "a"
END
is $re->to_regex, 'a*', 'simple repetition regex';

# parse simple plus repetition
$re = $parser->parse('a+');
is $re->to_string, <<END, 'plus repetition';
REPETITION (min: 1, max: oo):
    LITERAL: "a"
END
is $re->to_regex, 'a+', 'plus repetition regex';

# parse simple optional quantification
$re = $parser->parse('a?');
is $re->to_string, <<END, 'optional quantification';
REPETITION (min: 0, max: 1):
    LITERAL: "a"
END
is $re->to_regex, 'a?', 'optional quantification regex';

# parse exact quantification
$re = $parser->parse('a{5}');
is $re->to_string, <<END, 'exact quantification';
REPETITION (min: 5, max: 5):
    LITERAL: "a"
END
is $re->to_regex, 'a{5}', 'exact quantification';

# parse minimum quantification
$re = $parser->parse('a{17,}');
is $re->to_string, <<END, 'minimum quantification';
REPETITION (min: 17, max: oo):
    LITERAL: "a"
END
is $re->to_regex, 'a{17,}', 'minimum quantification regex';

# parse arbitrary quantification
$re = $parser->parse('a{17,42}');
is $re->to_string, <<END, 'arbitrary quantification';
REPETITION (min: 17, max: 42):
    LITERAL: "a"
END
is $re->to_regex, 'a{17,42}', 'arbitrary quantification regex';

# parse simple character class
$re = $parser->parse('[ab]');
is $re->to_string, <<END, 'character class';
ALTERNATION: (
    LITERAL: "a"
    LITERAL: "b"
)
END
is $re->to_regex, '(a|b)', 'character class regex';

# parse character class with meta characters
$re = $parser->parse('[a)*b]');
is $re->to_string, <<END, 'character class with meta characters';
ALTERNATION: (
    LITERAL: "a"
    LITERAL: ")"
    LITERAL: "*"
    LITERAL: "b"
)
END
is $re->to_regex, '(a|\\)|\\*|b)', 'character class regex';

# parse nested sequence
$re = $parser->parse('ab*(c|d)');
is $re->to_string, <<END, 'nested sequence';
SEQUENCE: (
    LITERAL: "a"
    REPETITION (min: 0, max: oo):
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
    REPETITION (min: 0, max: oo):
        LITERAL: "d"
)
END
is $re->to_regex, '(a|(bc)|d*)', 'nested alternation regex';

# parse nested repetition
$re = $parser->parse('(a|bc)*');
is $re->to_string, <<END, 'nested repetition';
REPETITION (min: 0, max: oo):
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
$re = $parser->parse('a(b|(cd*){17}|)+e{3,}|f*([gh]{17,42}i)?');
is $re->to_string, <<END, 'complex nested';
ALTERNATION: (
    SEQUENCE: (
        LITERAL: "a"
        REPETITION (min: 1, max: oo):
            ALTERNATION: (
                LITERAL: "b"
                REPETITION (min: 17, max: 17):
                    SEQUENCE: (
                        LITERAL: "c"
                        REPETITION (min: 0, max: oo):
                            LITERAL: "d"
                    )
                NOTHING
            )
        REPETITION (min: 3, max: oo):
            LITERAL: "e"
    )
    SEQUENCE: (
        REPETITION (min: 0, max: oo):
            LITERAL: "f"
        REPETITION (min: 0, max: 1):
            SEQUENCE: (
                REPETITION (min: 17, max: 42):
                    ALTERNATION: (
                        LITERAL: "g"
                        LITERAL: "h"
                    )
                LITERAL: "i"
            )
    )
)
END
is $re->to_regex, '((a(b|(cd*){17}|)+e{3,})|(f*((g|h){17,42}i)?))',
    'complex nested regex';

__END__
