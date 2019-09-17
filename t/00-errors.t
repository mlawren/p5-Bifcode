#!/usr/bin/env perl
use strict;
use warnings;
use Bifcode::V2;
use Test::More;

eval { Bifcode::V2::decode_bifcode2(undef) };
my $err = $@;

isa_ok $err, 'Bifcode::V2::Error::DecodeUsage';
like "$err", qr/input undefined/, 'error to string';

done_testing();
