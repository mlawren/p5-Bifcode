package Test::Bifcode;
use bytes;
use strict;
use warnings;
use utf8;
use boolean;
use Bifcode::V2 qw/decode_bifcodeV2 encode_bifcodeV2 force_bifcodeV2/;
use Carp;
use Exporter::Tidy default => [
    qw($bytes $BYTES $BYTES_KEY
      $utf8 $UTF8 $UTF8_KEY
      $data1 $DATA1
      $data2 $DATA2
      enc_ok
      encode_err
      decode_ok
      decode_err)
];
use Test2::V0;

our $utf8 = "\x{100}\x{df}";

#'ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ';
utf8::encode( my $utf8_bytes = $utf8 );
my $utf8_length = bytes::length($utf8_bytes);
our $UTF8     = 'u' . $utf8_length . '.' . $utf8_bytes . ',';
our $UTF8_KEY = 'u' . $utf8_length . '.' . $utf8_bytes . ':';

our $bytes = pack( 's<', 255 );
my $bytes_length = bytes::length($bytes);
our $BYTES     = 'b' . $bytes_length . '.' . $bytes . ',';
our $BYTES_KEY = 'b' . $bytes_length . '.' . $bytes . ':';

our $data1 = {
    bools   => [ false, true, ],
    bytes   => \$bytes,
    integer => 25,
    float   => -1.25e-9,
    undef   => undef,
    utf8    => $utf8,
};

our $DATA1 = '{'
  . ( 'u5.bools:' . '[f,t,]' )
  . ( 'u5.bytes:' . $BYTES )
  . ( 'u5.float:' . 'r-1.25e-9,' )
  . ( 'u7.integer:' . 'i25,' )
  . ( 'u5.undef:' . '~,' )
  . ( 'u4.utf8,' . $UTF8 ) . '}';

our $data2 = {
    bools   => [ false, true, ],
    bytes   => \$bytes,
    integer => 24,
    float   => 1.25e-9,
    undef   => undef,
    utf8    => $utf8,
};

our $DATA2 = '{'
  . ( 'u5.bools:' . '[f,t,]' )
  . ( 'u5.bytes:' . $BYTES )
  . ( 'u5.float:' . 'r1.25e-9,' )
  . ( 'u7.integer:' . 'i24,' )
  . ( 'u5.undef:' . '~,' )
  . ( 'u4.utf8:' . $UTF8 ) . '}';

sub enc_ok {
    croak 'usage: enc_ok($1,$2)'
      unless 2 == @_;
    my ( $thawed, $frozen, $testname ) = @_;
    is encode_bifcodeV2($thawed), $frozen, $testname // $frozen;
}

sub encode_err {
    my ( $data, $error, $kind_of_brokenness ) = @_;
    $kind_of_brokenness // Carp::croak 'encode_err needs $kind_of_brokenness';
    local $@;
    eval { encode_bifcodeV2 $data };
    my $have = ref $@;
    my $want = 'Bifcode::Error::' . $error;
    my $ok   = $have eq $want;
    ok $ok, "reject $kind_of_brokenness";
    diag "    wanted:  $want\n    got:     $have" unless $ok;
}

sub un {
    my ($frozen) = @_;
    local $, = ', ';
    my $frozen_str = $frozen // '*undef*';
    return 'ARRAY' eq ref $frozen
      ? ( "decode [@$frozen_str]", decode_bifcodeV2 @$frozen )
      : ( "decode '$frozen_str'", decode_bifcodeV2 $frozen );
}

sub decode_ok {
    my ( $frozen,   $thawed ) = @_;
    my ( $testname, $result ) = un $frozen;
    is $result, $thawed, $testname;
}

sub decode_err {
    my ( $frozen, $error, $kind_of_brokenness ) = @_;
    local $@;
    eval { un $frozen };
    my $have = ref $@;
    my $want = 'Bifcode::Error::' . $error;
    my $ok   = $have eq $want;
    ok $ok, "reject $kind_of_brokenness";
    diag "    wanted:  $want\n    got:     $have" unless $ok;
}

1;
