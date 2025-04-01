#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker::CPANfile;

my $diff = eval { require Text::Diff; require OptArgs2 };

WriteMakefile(
    NAME         => 'Bifcode2',
    ABSTRACT     => 'simple serialization format (version 2)',
    AUTHOR       => 'Mark Lawrence <nomad@null.net>',
    VERSION_FROM => 'lib/Bifcode2.pm',
    LICENSE      => 'perl_5',
    EXE_FILES    => $diff ? ['bin/diff-bifcode2'] : [],
    test         => {
        RECURSIVE_TEST_FILES => 1,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker =>
              { web => 'https://github.com/mlawren/p5-Bifcode/issues', },
            homepage   => 'https://github.com/mlawren/p5-Bifcode',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-Bifcode.git',
                web  => 'https//github.com/mlawren/p5-Bifcode',
            }
        },
    },
);
