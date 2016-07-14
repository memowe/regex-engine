#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 6;

use REE;

# illegal regex
eval {REE->new(regex => '*'); fail "didn't die"};
like $@, qr/^Parse error: unexpected */, 'died of regex parse error';

# regex matching
my $r = REE->new(regex => 'a(b|cd*|)+e|f*([gh]i)?');
ok $r->match('gi'), "'gi' matches";
ok ! $r->match('ffffh'), "'ffffh' doesn't match";
ok $r->match('abcbbcdddde'), "'abcbbcdddde' matches";
ok ! $r->match('abcbbcddddef'), "'abcbbcddddef' doesn't match";

# canonical regex
is $r->canonical_regex, '((a((b|(cd*)|)(b|(cd*)|)*)e)|(f*(|((g|h)i))))',
    'right canonical regex';

__END__
