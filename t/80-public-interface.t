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
my $r = REE->new(regex => 'a(b|cd*)*e|f*g');
ok $r->match('g'), "'g' matches";
ok ! $r->match('ffff'), "'ffff' doesn't match";
ok $r->match('abcbbcdddde'), "'abcbbcdddde' matches";
ok ! $r->match('abcbbcddddef'), "'abcbbcddddef' doesn't match";

# canonical regex
is $r->canonical_regex, '((a(b|(cd*))*e)|(f*g))', 'right canonical regex';

__END__
