#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Test2::V0;
use Test2::Require::Module 'Text::Diff';
use Test2::Require::Module 'OptArgs2';

my $cli = File::Spec->catfile( $RealBin, '..', 'bin', 'diff-bifcode2' );

{
    local $@;
    do $cli;
    isa_ok $@, 'OptArgs2::Usage::ArgRequired';
}

done_testing();
