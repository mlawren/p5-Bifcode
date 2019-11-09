#!/usr/bin/env perl
use strict;
use warnings;
use Bifcode2;
use Test2::V0;

eval { Bifcode2::decode_bifcode2(undef) };
my $err = $@;

isa_ok $err, 'Bifcode2::Error::DecodeUsage';
like "$err", qr/input undefined/, 'error to string';

done_testing();
