#!/usr/bin/env perl
use strict;
use warnings;
use Bifcode;
use Test2::V0;

eval { Bifcode::decode_bifcode(undef) };
my $err = $@;

isa_ok $err, 'Bifcode::Error::DecodeUsage';
like "$err", qr/input undefined/, 'error to string';

done_testing();
