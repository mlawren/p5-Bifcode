#!/usr/bin/env perl
use strict;
use warnings;
use Bifcode;
use Test::More;

eval { Bifcode::decode_bifcode(undef) };
my $err = $@;

isa_ok $err, 'Bifcode::Error::Decode';
like "$err", qr/garbage at 0/, 'error to string';

done_testing();
