use strict;
use warnings;
use utf8;
use Test::More 0.88;    # for done_testing
use Test::Differences;
use BBE 'encode_bbe', 'force_bbe';
require bytes;

my $utf8 =
'ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ';
utf8::encode( my $utf8_bytes = $utf8 );
my $utf8_length = bytes::length($utf8_bytes);
my $utf8_bbe    = $utf8_length . ':' . $utf8_bytes;

my $data        = pack( 's<', 255 );
my $data_length = bytes::length($data);
my $data_bbe    = $data_length . ';' . $data;

sub enc_ok {
    my ( $frozen, $thawed ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff encode_bbe($thawed), $frozen, "encode $frozen";
}

enc_ok '~'                      => undef;
enc_ok 'T'                      => $BBE::TRUE;
enc_ok 'F'                      => $BBE::FALSE;
enc_ok 'i4,'                    => 4;
enc_ok 'i5,'                    => force_bbe( 5, 'integer' );
enc_ok 'i0,'                    => 0;
enc_ok 'i-10,'                  => -10;
enc_ok 'i12345678901234567890,' => '12345678901234567890';
enc_ok '0:'                     => '';
enc_ok $utf8_bbe                => $utf8;
enc_ok $data_bbe       => force_bbe( $data,        'bytes' );
enc_ok $data_bbe       => \$data;
enc_ok '3:abc'         => 'abc';
enc_ok '10:1234567890' => force_bbe( '1234567890', 'utf8' );
enc_ok '[]'            => [];
enc_ok '[i1,i2,~' . $utf8_bbe . ']' => [ 1, 2, undef, $utf8 ];
enc_ok '[[5:Alice3:Bob][i2,i3,]]' => [ [ 'Alice', 'Bob' ], [ 2, 3 ] ];
enc_ok '{}' => {};
enc_ok '{1:13:one}' => { 1 => 'one' };
enc_ok '{4:data' . $data_bbe . '}' => { data => force_bbe( $data, 'bytes' ) },
    enc_ok '{3:agei25,4:eyes4:blue5:falseF4:trueT5:undef~'
  . $utf8_bbe
  . $utf8_bbe
  . '}' => {
    'age'   => 25,
    'eyes'  => 'blue',
    'false' => $BBE::FALSE,
    'true'  => $BBE::TRUE,
    'undef' => undef,
    $utf8   => $utf8,
  };
enc_ok '{8:spam.mp3{6:author5:Alice'
  . '4:data'
  . $data_bbe
  . '6:lengthi100000,5:undef~'
  . '}}' => {
    'spam.mp3' => {
        'author' => 'Alice',
        'data'   => force_bbe( $data, 'bytes' ),
        'length' => 100000,
        'undef'  => undef,
    }
  };

done_testing;
