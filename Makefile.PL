#!/usr/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME         => 'Bifcode',
    AUTHOR       => 'Mark Lawrencde <nomad@null.net>',
    VERSION_FROM => 'lib/Bifcode.pm',
    META_ADD     => {
        resources => {
            repository => 'https://github.com/mlawren/p5-Bifcode',
        }
    },
    META_MERGE => {
        no_index => {
            package => [qw(Bifcode::Boolean)],
        },
    },
);
