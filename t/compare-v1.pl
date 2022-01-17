#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Benchmark 'cmpthese';
use Bifcode2 ();
use Bifcode  ();

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
        'Bifcode'  => sub { Bifcode::encode_bifcode $h1 },
        'Bifcode2' => sub { Bifcode2::encode_bifcode2 $h1},
    }
);

say '';
say 'Decoding:';

my $b1 = ''
  . Bifcode::encode_bifcode {
    bools   => [ boolean::false, boolean::true, ],
    bytes   => \pack( 's<', 255 ),
    integer => 25,
    real    => 1.25e-5,
    null    => undef,
    utf8    => "Ελύτη",
  };

my $b2 = ''
  . Bifcode2::encode_bifcode2 {
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
        'Bifcode'  => sub { Bifcode::decode_bifcode $b1 },
        'Bifcode2' => sub { Bifcode2::decode_bifcode2 $b2},
    }
);

#DB::disable_profile();
