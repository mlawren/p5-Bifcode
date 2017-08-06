use strict;
use warnings;
use utf8;
use Test::More 0.88;    # for done_testing
use Test::Differences;
use Bifcode 'encode_bifcode', 'force_bifcode';
require bytes;

my $utf8 =
'ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ';
utf8::encode( my $utf8_bytes = $utf8 );
my $utf8_length  = bytes::length($utf8_bytes);
my $utf8_bifcode = 'U' . $utf8_length . ':' . $utf8_bytes;

my $data         = pack( 's<', 255 );
my $data_length  = bytes::length($data);
my $data_bifcode = 'B' . $data_length . ':' . $data;

sub enc_ok {
    my ( $frozen, $thawed ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff encode_bifcode($thawed), $frozen, "encode $frozen";
}

enc_ok '~'                      => undef;
enc_ok '1'                      => $Bifcode::TRUE;
enc_ok '0'                      => $Bifcode::FALSE;
enc_ok 'I4,'                    => 4;
enc_ok 'I5,'                    => force_bifcode( 5, 'integer' );
enc_ok 'I0,'                    => 0;
enc_ok 'I-10,'                  => -10;
enc_ok 'I12345678901234567890,' => '12345678901234567890';
enc_ok 'F0.1e1,'                => '0.1e1';
enc_ok 'F1.001e13,'             => '1.001e13';
enc_ok 'U0:'                    => '';
enc_ok $utf8_bifcode            => $utf8;
enc_ok $data_bifcode    => force_bifcode( $data,        'bytes' );
enc_ok $data_bifcode    => \$data;
enc_ok 'U3:abc'         => 'abc';
enc_ok 'U10:1234567890' => force_bifcode( '1234567890', 'utf8' );
enc_ok '[]'             => [];
enc_ok '[I1,I2,~' . $utf8_bifcode . ']' => [ 1, 2, undef, $utf8 ];
enc_ok '[[U5:AliceU3:Bob][I2,I3,]]' => [ [ 'Alice', 'Bob' ], [ 2, 3 ] ];
enc_ok '{}' => {};
enc_ok '{U1:1U3:one}' => { 1 => 'one' };
enc_ok '{U4:data'
  . $data_bifcode
  . '}' => { data => force_bifcode( $data, 'bytes' ) },
  enc_ok '{U3:ageI25,U4:eyesU4:blueU5:false0U4:true1U5:undef~'
  . $utf8_bifcode
  . $utf8_bifcode
  . '}' => {
    'age'   => 25,
    'eyes'  => 'blue',
    'false' => $Bifcode::FALSE,
    'true'  => $Bifcode::TRUE,
    'undef' => undef,
    $utf8   => $utf8,
  };
enc_ok '{U8:spam.mp3{U6:authorU5:Alice'
  . 'U4:data'
  . $data_bifcode
  . 'U6:lengthI100000,U5:undef~'
  . '}}' => {
    'spam.mp3' => {
        'author' => 'Alice',
        'data'   => force_bifcode( $data, 'bytes' ),
        'length' => 100000,
        'undef'  => undef,
    }
  };

done_testing;
