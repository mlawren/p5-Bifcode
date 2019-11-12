#!/usr/bin/env perl
use strict;
use warnings;
use Bifcode::V1;
use Test::More;

eval { Bifcode::V1::decode_bifcode(undef) };
my $err = $@;

isa_ok $err, 'Bifcode::Error::DecodeUsage';
like "$err", qr/input undefined/, 'error to string';

done_testing();
