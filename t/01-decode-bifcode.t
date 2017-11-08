use strict;
use warnings;
use lib 'lib';
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use boolean;
use Test::Bifcode;
use Test::More 0.88;    # for done_testing

subtest UNDEF => sub {
    decod_ok '~' => undef;
};

subtest BOOLEAN => sub {
    decod_ok '1' => boolean::true;
    decod_ok '0' => boolean::false;
};

subtest INTEGER => sub {
    error_ok 'I'           => 'DecodeIntegerEnd', 'aborted integer';
    error_ok 'I0'          => 'DecodeInteger',    'unterminated integer';
    error_ok 'I,'          => 'DecodeInteger',    'empty integer';
    error_ok 'I341foo382,' => 'DecodeInteger',    'malformed integer';
    decod_ok 'I4,'         => 4;
    decod_ok 'I0,'         => 0;
    decod_ok 'I123456789,' => 123456789;
    decod_ok 'I-10,'       => -10;
    error_ok 'I-0,'        => 'DecodeInteger',    'negative zero integer';
    error_ok 'I123'        => 'DecodeInteger',    'unterminated integer';
    error_ok 'I6,asd' => 'DecodeTrailing', 'integer with trailing garbage';
    error_ok 'I03,'   => 'DecodeInteger',  'integer with leading zero';
    error_ok 'I-03,'  => 'DecodeInteger',  'negative integer with leading zero';
};

subtest FLOAT => sub {
    error_ok 'F'     => 'DecodeFloatEnd', 'aborted float';
    error_ok 'F0'    => 'DecodeFloat',    'aborted float';
    error_ok 'F0.'   => 'DecodeFloat',    'aborted float';
    error_ok 'F0.0'  => 'DecodeFloat',    'aborted float';
    error_ok 'F0.0e' => 'DecodeFloat',    'aborted float';
    error_ok 'F0.e0' => 'DecodeFloat',    'aborted float';
    error_ok 'F0e0'  => 'DecodeFloat',    'aborted float';
    decod_ok 'F0.0e0,'  => '0.0e0';
    decod_ok 'F4.1e-2,' => '4.1e-2';
    error_ok 'F-0.0e0,' => 'DecodeFloat', 'non-zero exponent for 0.0 float';
    error_ok 'F0.0e-1,' => 'DecodeFloat', 'non-zero exponent for 0.0 float';
};

subtest UTF8 => sub {
    error_ok
      'U0:U0:' => 'DecodeTrailing',
      'data past end of first correct encode_bifcode\'d string';
    error_ok 'U1:' => 'DecodeUTF8End', 'string longer than data';
    error_ok
      'U35208734823ljdahflajhdf' => 'DecodeUTF8',
      'garbage looking vaguely like a string, with large count';
    error_ok
      'U2:abfdjslhfld' => 'DecodeTrailing',
      'string with trailing garbage';
    decod_ok $UTF8            => $utf8;
    decod_ok 'U0:'            => '';
    decod_ok 'U3:abc'         => 'abc';
    decod_ok 'U3:abc'         => 'abc';
    decod_ok 'U10:1234567890' => '1234567890';
    error_ok
      'U02:xy' => 'DecodeUTF8',
      'string with extra leading zero in count';
    error_ok 'U9999:x' => 'DecodeUTF8End', 'string shorter than count';
    decod_ok "U2:\x0A\x0D" => "\x0A\x0D";
    error_ok
      'U00:' => 'DecodeUTF8',
      'zero-length string with extra leading zero in count';
};

subtest BYTES => sub {
    error_ok 'B23'  => 'DecodeBytes',    'incomplete bytes definition';
    error_ok 'Bxxx' => 'DecodeBytes',    'invalid bytes definition';
    error_ok 'B2:1' => 'DecodeBytesEnd', 'bytes not long enough';
    decod_ok $BYTES => $bytes;
};

subtest LIST => sub {
    error_ok '[' => 'DecodeEnd', 'unclosed empty list';
    decod_ok '[]' => [];
    error_ok
      '[]anfdldjfh' => 'DecodeTrailing',
      'empty list with trailing garbage';
    decod_ok '[~~~]' => [ undef, undef, undef ];
    decod_ok '[10]' => [ boolean::true, boolean::false ];
    decod_ok '[U0:U0:U0:]'                => [ '',    '',   '' ];
    decod_ok '[I1,I2,I3,]'                => [ 1,     2,    3 ];
    decod_ok '[U3:asdU2:xy' . $UTF8 . ']' => [ 'asd', 'xy', $utf8 ];
    decod_ok '[[U5:AliceU3:Bob][I2,I3,~]~]' =>
      [ [ 'Alice', 'Bob' ], [ 2, 3, undef ], undef ];
    error_ok '[U0:' => 'DecodeEnd', 'unclosed list with content';
    error_ok
      '[U01:a]' => 'DecodeUTF8',
      'list with string with leading zero in count';
    error_ok '[U-3:]' => 'DecodeUTF8', 'list with negative-length string';

};

subtest DICT => sub {
    error_ok '{'        => 'DecodeEnd',      'unclosed empty dict';
    error_ok '{}foobar' => 'DecodeTrailing', 'empty dict with trailing garbage';
    decod_ok '{}'       => {};
    decod_ok '{' . $BYTES . $UTF8 . '}' => { $bytes => $utf8 };
    decod_ok '{' . $UTF8 . $BYTES . '}' => { $utf8  => $bytes };
    decod_ok '{U3:ageI25,U4:eyesU4:blueU5:false0U4:true1U5:undef~}' => {
        'age'   => 25,
        'eyes'  => 'blue',
        'undef' => undef,
        true    => boolean::true,
        false   => boolean::false,
    };
    decod_ok '{U8:spam.mp3{U6:authorU5:AliceU6:lengthI100000,U5:undef~}}' =>
      { 'spam.mp3' =>
          { 'author' => 'Alice', 'length' => 100000, 'undef' => undef } };

    error_ok '{~}'      => 'DecodeKey',      'dict key cannot be undef';
    error_ok '{U3:foo}' => 'DecodeKeyValue', 'dict with odd number of elements';
    error_ok '{I1,U0:}' => 'DecodeKey',      'dict with integer key';
    error_ok '{U1:bU0:U1:aU0:}' => 'DecodeKeySortOrder', 'missorted keys';
    error_ok '{U1:aU0:U1:aU0:}' => 'DecodeKeyDuplicate', 'duplicate keys';
    error_ok '{U0:' => 'DecodeEnd', 'unclosed dict with odd number of elements';
    error_ok '{U0:U0:' => 'DecodeEnd', 'unclosed dict with content';

};

subtest nest_limits => sub {
    decod_ok [ '[U0:]', 1 ] => [''];    # Accept single list when max_depth is 1
    error_ok [ '[U0:]', 0 ] => 'DecodeDepth', 'single list when max_depth is 0';

    # Accept a nested list when max_depth is 2
    decod_ok [ '[[U0:]]', 2 ] => [ [''] ];
    error_ok [ '[[U0:]]', 1 ] => 'DecodeDepth',
      'nested list when max_depth is 1';

    # Accept list containing dict when max_depth is 2
    decod_ok [ '[{U1:aU0:}]', 2 ] => [ { 'a' => '' } ];

    error_ok [ '[{U1:aU0:}]', 1 ] => 'DecodeDepth',
      'dict in list when max_depth is 1';

    # Accept single dict when max_depth is 1
    decod_ok [ '{U1:aU0:}', 1 ] => { a => '' };
    error_ok [ '{U1:aU0:}', 0 ] => 'DecodeDepth',
      'single dict when max_depth is 0';

    # Accept a nested dict when max_depth is 2
    decod_ok [ '{U1:a{U1:aU0:}}', 2 ] => { a => { a => '' } };
    error_ok [ '{U1:a{U1:aU0:}}', 1 ] => 'DecodeDepth',
      'nested dict when max_depth is 1';

    # Accept dict containing list when max_depth is 2
    decod_ok [ '{U1:a[U0:]}', 2 ] => { a => [''] };
    error_ok [ '{U1:a[U0:]}', 1 ] => 'DecodeDepth',
      'list in dict when max_depth is 1';

    # Accept dict containing list when max_depth is 2
    decod_ok [ '{U1:aU0:U1:b[U0:]}', 2 ] => { a => '', b => [''] };
    error_ok [ '{U1:aU0:U1:b[U0:]}', 1 ] => 'DecodeDepth',
      'list in dict when max_depth is 1';
};

error_ok [ '[U0:]', 0, 'arg3' ] => 'DecodeUsage',
  'decode_bifcode only takes up to 2 args';
error_ok '' => 'DecodeEnd', 'empty data';
error_ok $utf8 => 'DecodeUsage',
  'check for utf8 flag';
error_ok 'relwjhrlewjh' => 'Decode', 'complete garbage';

done_testing;
