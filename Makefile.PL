#!/usr/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME         => 'BBE',
    AUTHOR       => 'Mark Lawrencde <nomad@null.net>',
    VERSION_FROM => 'lib/BBE.pm',
);
