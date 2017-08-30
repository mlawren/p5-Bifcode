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
      $data1 $DATA1
      $data2 $DATA2
      enc_ok
      enc_error_ok
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

our $data1 = {
    bools   => [ $Bifcode::FALSE, $Bifcode::TRUE, ],
    bytes   => \$bytes,
    integer => 25,
    float   => 1.0 / 8.0e9,
    undef   => undef,
    utf8    => $utf8,
};

our $DATA1 = '{'
  . ( 'U5:bools' . '[01]' )
  . ( 'U5:bytes' . $BYTES )
  . ( 'U5:float' . 'F1.25e-10,' )
  . ( 'U7:integer' . 'I25,' )
  . ( 'U5:undef' . '~' )
  . ( 'U4:utf8' . $UTF8 ) . '}';

our $data2 = {
    bools   => [ $Bifcode::FALSE, $Bifcode::TRUE, ],
    bytes   => \$bytes,
    integer => 24,
    float   => 1.0 / 8.0e8,
    undef   => undef,
    utf8    => $utf8,
};

our $DATA2 = '{'
  . ( 'U5:bools' . '[01]' )
  . ( 'U5:bytes' . $BYTES )
  . ( 'U5:float' . 'F1.25e-9,' )
  . ( 'U7:integer' . 'I24,' )
  . ( 'U5:undef' . '~' )
  . ( 'U4:utf8' . $UTF8 ) . '}';

sub enc_ok {
    croak 'usage: enc_ok($1,$2)'
      unless 2 == @_;
    my ( $thawed, $frozen ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff encode_bifcode($thawed), $frozen, "encode $frozen";
}

sub enc_error_ok {
    my ( $data, $error_rx, $kind_of_brokenness ) = @_;
    local $@;
    eval { encode_bifcode $data };
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like $@, $error_rx, "reject $kind_of_brokenness";
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
