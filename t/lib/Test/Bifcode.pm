package Test::Bifcode;
use bytes;
use strict;
use warnings;

use utf8;
use Bifcode qw/decode_bifcode encode_bifcode force_bifcode/;
use Carp;
use Exporter::Tidy default => [
    qw($bytes $BYTES
      $utf8 $UTF8
      enc_ok
      un
      decod_ok
      error_ok)
];
use Test::More 0.88;    # for done_testing
use Test::Differences;

our $utf8 = "\x{100}\x{df}";

#'ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ';
utf8::encode( my $utf8_bytes = $utf8 );
my $utf8_length = bytes::length($utf8_bytes);
our $UTF8 = 'U' . $utf8_length . ':' . $utf8_bytes;

our $bytes = pack( 's<', 255 );
my $bytes_length = bytes::length($bytes);
our $BYTES = 'B' . $bytes_length . ':' . $bytes;

sub enc_ok {
    croak 'usage: enc_ok($1,$2)'
      unless 2 == @_;
    my ( $thawed, $frozen ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff encode_bifcode($thawed), $frozen, "encode $frozen";
}

sub un {
    my ($frozen) = @_;
    local $, = ', ';
    return 'ARRAY' eq ref $frozen
      ? ( "decode [@$frozen]", decode_bifcode @$frozen )
      : ( "decode '$frozen'", decode_bifcode $frozen );
}

sub decod_ok {
    my ( $frozen,   $thawed ) = @_;
    my ( $testname, $result ) = un $frozen;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff $result, $thawed, $testname;
}

sub error_ok {
    my ( $frozen, $error_rx, $kind_of_brokenness ) = @_;
    local $@;
    eval { un $frozen };
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like $@, $error_rx, "reject $kind_of_brokenness";
}

1;
