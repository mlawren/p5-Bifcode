#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME         => 'Bifcode',
    ABSTRACT     => 'encode and decode BIFCODE serialization format',
    AUTHOR       => 'Mark Lawrencde <nomad@null.net>',
    VERSION_FROM => 'lib/Bifcode.pm',
    LICENSE      => 'perl_5',
    EXE_FILES    => ['bin/diff-bifcode'],
    META_MERGE   => {
        'meta-spec' => { version => 2 },
        no_index    => {
            package => [
                qw(
                  Bifcode::BIFCODE
                  )
            ],
        },
        resources => {
            bugtracker =>
              { web => 'https//github.com/mlawren/p5-Bifcode/issues', },
            homepage   => 'https//github.com/mlawren/p5-Bifcode',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-Bifcode.git',
                web  => 'https//github.com/mlawren/p5-Bifcode',
            }
        },
    },
);
