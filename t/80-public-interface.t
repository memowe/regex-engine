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
my $r = REE->new(regex => 'a(b|(cd*){17}|)+e{3,}|f*([gh]{17,42}i)?');
ok $r->match('gggghhhhghghhghghi'), "'gggghhhhghghhghghi' matches";
ok ! $r->match('aee'), "'aee' doesn't match";
ok $r->match('abeeeee'), "'abeeeee' matches";
ok ! $r->match('abbccccccccdddccccccccdeee'),
    "'abbccccccccdddccccccccdeee' doesn't match";

# canonical regex
is $r->canonical_regex, '((a(b|(cd*){17}|)+e{3,})|(f*((g|h){17,42}i)?))',
    'right canonical regex';

__END__
