#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Test2::V0;

my $cli = File::Spec->catfile( $RealBin, '..', 'bin', 'diff-bifcode' );

{
    local $@;
    do $cli;
    isa_ok $@, 'OptArgs2::Usage::ArgRequired';
}

done_testing();
