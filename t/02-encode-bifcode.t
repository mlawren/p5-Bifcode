use strict;
use warnings;
use lib 'lib';
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use Test::Bifcode;
use Test::More 0.88;    # for done_testing
use Bifcode 'encode_bifcode', 'force_bifcode';

subtest 'UNDEF' => sub {
    enc_ok undef, '~';
};

subtest 'BOOLEAN' => sub {
    enc_ok $Bifcode::TRUE  => '1';
    enc_ok $Bifcode::FALSE => '0';
};

subtest 'INTEGER' => sub {
    enc_ok 4 => 'I4,';
    enc_ok force_bifcode( 5, 'integer' ) => 'I5,';
    enc_ok 0                      => 'I0,';
    enc_ok - 10                   => 'I-10,';
    enc_ok '12345678901234567890' => 'I12345678901234567890,';
    enc_ok force_bifcode( '00', 'integer' ) => 'I0,';
    enc_error_ok force_bifcode( '00abc', 'integer' ) =>
      qr/Argument "00abc" isn't numeric in addition/,
      'forcing a non-integer as integer';
};

subtest 'FLOAT' => sub {
    enc_ok '0.1e1'    => 'F0.1e1,';
    enc_ok '1.001e13' => 'F1.001e13,';
    enc_error_ok force_bifcode( '00abc', 'float' ) =>
      qr/Argument "00abc" isn't numeric in addition/,
      'forcing a non-float as float';
};

subtest 'UTF8' => sub {
    enc_ok ''    => 'U0:';
    enc_ok $utf8 => $UTF8;
    enc_ok 'abc' => 'U3:abc';
    enc_ok force_bifcode( '1234567890', 'utf8' ) => 'U10:1234567890';
    enc_ok force_bifcode( '0',          'utf8' ) => 'U1:0';
    enc_ok '00' => 'U2:00';
};

subtest 'BYTES' => sub {
    enc_ok force_bifcode( $bytes, 'bytes' ) => $BYTES;
    enc_ok \$bytes => $BYTES;
};

subtest 'LIST' => sub {
    enc_ok [] => '[]';
    enc_ok [ 1, 2, undef, $utf8 ] => '[I1,I2,~' . $UTF8 . ']';
    enc_ok [ [ 'Alice', 'Bob' ], [ 2, 3 ] ] => '[[U5:AliceU3:Bob][I2,I3,]]';
};

subtest 'DICT' => sub {
    enc_ok {} => '{}';
    enc_ok { 1 => 'one' } => '{U1:1U3:one}';
    enc_ok { bytes => force_bifcode( $bytes, 'bytes' ) } => '{U5:bytes'
      . $BYTES . '}';

    enc_ok {
        'age'   => 25,
        'eyes'  => 'blue',
        'false' => $Bifcode::FALSE,
        'true'  => $Bifcode::TRUE,
        'undef' => undef,
        $utf8   => $utf8,
      } => '{U3:ageI25,U4:eyesU4:blueU5:false0U4:true1U5:undef~'
      . $UTF8
      . $UTF8 . '}';

    enc_ok {
        'spam.mp3' => {
            'author' => 'Alice',
            'bytes'  => force_bifcode( $bytes, 'bytes' ),
            'length' => 100000,
            'undef'  => undef,
        }
      } => '{U8:spam.mp3{U6:authorU5:Alice'
      . 'U5:bytes'
      . $BYTES
      . 'U6:lengthI100000,U5:undef~' . '}}';
};

done_testing;
