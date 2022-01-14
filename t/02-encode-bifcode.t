use strict;
use warnings;
use lib 'lib';
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use boolean;
use Test::Bifcode;
use Test2::V0;
use Bifcode::V2 'encode_bifcodeV2', 'force_bifcodeV2';

subtest 'UNDEF' => sub {
    enc_ok undef, '~,';
};

subtest 'BOOLEAN' => sub {
    enc_ok boolean::true  => 't,';
    enc_ok boolean::false => 'f,';
};

subtest 'INTEGER' => sub {
    enc_ok 4                                      => 'i4,';
    enc_ok force_bifcodeV2( 5, 'integer' )        => 'i5,';
    enc_ok 0                                      => 'i0,';
    enc_ok - 10                                   => 'i-10,';
    enc_ok '12345678901234567890'                 => 'i12345678901234567890,';
    encode_err force_bifcodeV2( '00', 'integer' ) => 'EncodeInteger',
      'invalid 00 integer';
    encode_err force_bifcodeV2( '00abc', 'integer' ) => 'EncodeInteger',
      'forcing a non-integer as integer';

    my $u = undef;
    encode_err bless( \$u, 'Bifcode::INTEGER' ) => 'EncodeIntegerUndef',
      'forcing undef as integer';
};

subtest 'REAL' => sub {
    enc_ok '0.0' => 'r0.0e0,';

    enc_ok '1.0e0'  => 'r1.0e0,';
    enc_ok '1.0e1'  => 'r1.0e1,';
    enc_ok '1.0e-1' => 'r1.0e-1,';

    enc_ok '-1.0e0'  => 'r-1.0e0,';
    enc_ok '-1.0e1'  => 'r-1.0e1,';
    enc_ok '-1.0e-1' => 'r-1.0e-1,';

    #    enc_ok '0100.2e0'   => 'r100.2e0,'; # leading 0 removed

    enc_ok '100.2'   => 'r100.2e0,';     # add missing e
    enc_ok '100.20'  => 'r100.2e0,';     # trailing 0 removed
    enc_ok '100.08'  => 'r100.08e0,';    # leading .0 kept
    enc_ok '100.080' => 'r100.08e0,';    # trailing 0 removed leading .0 kept

    enc_ok '100.1e1'   => 'r100.1e1,';   # unchanged
    enc_ok '100.10e1'  => 'r100.1e1,';   # trailing 0 removed
    enc_ok '100.01e1'  => 'r100.01e1,';  # leading .0 kept
    enc_ok '100.010e1' => 'r100.01e1,';  # trailing 0 removed leading .0 kept

    enc_ok '100e0'    => 'r100.0e0,';    # ensure decimal
    enc_ok '100e01'   => 'r100.0e1,';
    enc_ok '100e1'    => 'r100.0e1,';
    enc_ok '100e9'    => 'r100.0e9,';
    enc_ok '100e11'   => 'r100.0e11,';
    enc_ok '100e-1'   => 'r100.0e-1,';
    enc_ok '100e-9'   => 'r100.0e-9,';
    enc_ok '100e-09'  => 'r100.0e-9,';
    enc_ok '100e-011' => 'r100.0e-11,';

    enc_ok 3.33333333e-8 => 'r3.33333333e-8,';

    # Plain integer
    enc_ok force_bifcodeV2( 0, 'real' ) => 'r0.0e0,';

    # Plain real
    enc_ok force_bifcodeV2( '100.2', 'real' ) => 'r100.2e0,';

    # Plain real trailing .x0
    enc_ok force_bifcodeV2( '100.20', 'real' ) => 'r100.2e0,';

    # Plain real leading .0x
    enc_ok force_bifcodeV2( '100.08', 'real' ) => 'r100.08e0,';

    # exponent no decimal
    enc_ok force_bifcodeV2( '100e0', 'real' ) => 'r100.0e0,';

    # decimal and exponent
    enc_ok force_bifcodeV2( '100.2e0', 'real' ) => 'r100.2e0,';

    # decimal and exponent leading .0x
    enc_ok force_bifcodeV2( '100.008e0', 'real' ) => 'r100.008e0,';

    encode_err force_bifcodeV2( '00abc', 'real' ) => 'EncodeReal',
      'forcing a non-real as real';

    my $u = undef;
    encode_err bless( \$u, 'Bifcode::REAL' ) => 'EncodeRealUndef',
      'forcing undef as real';
};

subtest 'UTF8' => sub {
    enc_ok ''    => 'u0.,';
    enc_ok $utf8 => $UTF8;
    ok utf8::is_utf8($utf8), 'still have utf8 flag on source string';
    enc_ok 'abc'                                   => 'u3.abc,';
    enc_ok force_bifcodeV2( '1234567890', 'utf8' ) => 'u10.1234567890,';
    enc_ok force_bifcodeV2( '0', 'utf8' )          => 'u1.0,';
    enc_ok '00'                                    => 'u2.00,';

    my $u = undef;
    encode_err bless( \$u, 'Bifcode::UTF8' ) => 'EncodeUTF8Undef',
      'forcing undef as utf8';
};

subtest 'BYTES' => sub {
    enc_ok force_bifcodeV2( $bytes, 'bytes' ) => $BYTES;
    enc_ok \$bytes                            => $BYTES;

    my $u = undef;
    encode_err \$u => 'EncodeBytesUndef', 'scalar ref to undef';
    encode_err bless( \$u, 'Bifcode::BYTES' ) => 'EncodeBytesUndef',
      'forcing undef as bytes';
};

subtest 'LIST' => sub {
    enc_ok []                               => '[]';
    enc_ok [ 1, 2, undef, $utf8 ]           => '[i1,i2,~,' . $UTF8 . ']';
    enc_ok [ [ 'Alice', 'Bob' ], [ 2, 3 ] ] => '[[u5.Alice,u3.Bob,][i2,i3,]]';
};

subtest 'DICT' => sub {
    enc_ok {} => '{}';
    enc_ok { 1 => 'one' } => '{u1.1:u3.one,}';
    enc_ok { 1.5 => 'one' } => '{u3.1.5:u3.one,}';
    enc_ok { bytes => force_bifcodeV2( $bytes, 'bytes' ) } => '{u5.bytes:'
      . $BYTES . '}';

    enc_ok {
        'age'   => 25,
        'eyes'  => 'blue',
        'false' => boolean::false,
        'true'  => boolean::true,
        'undef' => undef,
        $utf8   => $utf8,
      } => '{u3.age:i25,u4.eyes:u4.blue,u5.false:f,u4.true:t,u5.undef:~,'
      . $UTF8_KEY
      . $UTF8 . '}';

    enc_ok {
        'spam.mp3' => {
            'author' => 'Alice',
            'bytes'  => force_bifcodeV2( $bytes, 'bytes' ),
            'length' => 100000,
            'undef'  => undef,
        }
      } => '{u8.spam.mp3:{u6.author:u5.Alice,'
      . 'u5.bytes:'
      . $BYTES
      . 'u6.length:i100000,u5.undef:~,' . '}}';
};

my $u = undef;
encode_err bless( \$u, 'strange' ) => 'EncodeUnhandled',
  'unknown object type';

eval { encode_bifcodeV2() };
isa_ok $@, ['Bifcode::Error::EncodeUsage'], 'not enough arguments';
eval { encode_bifcodeV2( 1, 2, 3 ) };
isa_ok $@, ['Bifcode::Error::EncodeUsage'], 'too many arguments';

done_testing;
