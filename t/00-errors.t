#!/usr/bin/env perl
use strict;
use warnings;
use Bifcode::V2;
use Test2::V0;

eval { Bifcode::V2::decode_bifcodeV2(undef) };
my $err = $@;

isa_ok $err, 'Bifcode::Error::DecodeUsage';
like "$err", qr/input undefined/, 'error to string';

done_testing();
