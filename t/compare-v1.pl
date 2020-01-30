#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Benchmark 'cmpthese';
use Bifcode::V2 ();
use Bifcode::V1 ();

#DB::enable_profile();

my $h1 = {
    bools   => [ boolean::false, boolean::true, ],
    bytes   => \pack( 's<', 255 ),
    integer => 25,
    real    => 1.25e-5,
    null    => undef,
    utf8    => "Ελύτη",
};

say 'Encoding:';
cmpthese(
    10000,
    {
        'Bifcode::V1' => sub { Bifcode::V1::encode_bifcode $h1 },
        'Bifcode::V2' => sub { Bifcode::V2::encode_bifcode $h1},
    }
);

say '';
say 'Decoding:';

my $b1 = ''
  . Bifcode::V1::encode_bifcode {
    bools   => [ boolean::false, boolean::true, ],
    bytes   => \pack( 's<', 255 ),
    integer => 25,
    real    => 1.25e-5,
    null    => undef,
    utf8    => "Ελύτη",
  };

my $b2 = ''
  . Bifcode::V2::encode_bifcode {
    bools   => [ boolean::false, boolean::true, ],
    bytes   => \pack( 's<', 255 ),
    integer => 25,
    real    => 1.25e-5,
    null    => undef,
    utf8    => "Ελύτη",
  };

cmpthese(
    10000,
    {
        'Bifcode::V1' => sub { Bifcode::V1::decode_bifcode $b1 },
        'Bifcode::V2' => sub { Bifcode::V2::decode_bifcode $b2},
    }
);

#DB::disable_profile();
