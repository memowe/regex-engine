use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'REE',
    AUTHOR              => q{Mirko Westermeier <mirko@westermeier.de>},
    VERSION_FROM        => 'lib/REE.pm',
    LICENSE             => 'mit',
    MIN_PERL_VERSION    => 5.010,
    PREREQ_PM           => {},
    test                => {TESTS => 't/*.t'},
);
