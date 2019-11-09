use strict;
use warnings;
use lib 'lib';
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use boolean;
use Test::Bifcode2;
use Test2::V0;

subtest UNDEF => sub {
    decode_ok '~,' => undef;
};

subtest BOOLEAN => sub {
    decode_ok 't,' => boolean::true;
    decode_ok 'f,' => boolean::false;
};

subtest INTEGER => sub {
    decode_err 'i'           => 'DecodeIntegerTrunc', 'aborted integer';
    decode_err 'i0'          => 'DecodeInteger',      'unterminated integer';
    decode_err 'i,'          => 'DecodeInteger',      'empty integer';
    decode_err 'i341foo382,' => 'DecodeInteger',      'malformed integer';
    decode_ok 'i4,'          => 4;
    decode_ok 'i0,'          => 0;
    decode_ok 'i123456789,'  => 123456789;
    decode_ok 'i-10,'        => -10;
    decode_err 'i-0,'        => 'DecodeInteger',      'negative zero integer';
    decode_err 'i123'        => 'DecodeInteger',      'unterminated integer';
    decode_err 'i6,asd' => 'DecodeTrailing', 'integer with trailing garbage';
    decode_err 'i03,'   => 'DecodeInteger',  'integer with leading zero';
    decode_err 'i-03,' => 'DecodeInteger', 'negative integer with leading zero';
};

subtest REAL => sub {
    decode_err 'r'     => 'DecodeRealTrunc', 'aborted real';
    decode_err 'r0'    => 'DecodeReal',      'aborted real';
    decode_err 'r0.'   => 'DecodeReal',      'aborted real';
    decode_err 'r0.0'  => 'DecodeReal',      'aborted real';
    decode_err 'r0.0e' => 'DecodeReal',      'aborted real';
    decode_err 'r0.e0' => 'DecodeReal',      'aborted real';
    decode_err 'r0e0'  => 'DecodeReal',      'aborted real';
    decode_ok 'r0.0e0,'   => 0.0e0;
    decode_ok 'r4.1e-2,'  => 4.1e-2;
    decode_err 'r-0.0e0,' => 'DecodeReal', 'non-zero exponent for 0.0 real';
    decode_err 'r0.0e-1,' => 'DecodeReal', 'non-zero exponent for 0.0 real';
};

subtest UTF8 => sub {
    decode_err
      'u0.,u0.' => 'DecodeTrailing',
      'data past end of first correct encode_bifcode2\'d string';
    decode_err 'u1.'  => 'DecodeUTF8Trunc', 'string longer than data';
    decode_err 'u1.1' => 'DecodeUTF8Term',  'string missing terminator';
    decode_err
      'u35208734823ljdahflajhdf' => 'DecodeUTF8',
      'garbage looking vaguely like a string, with large count';
    decode_err
      'u2.abfdjslhfld' => 'DecodeUTF8Term',
      'string with trailing garbage';
    decode_ok $UTF8             => $utf8;
    decode_ok 'u0.,'            => '';
    decode_ok 'u3.abc,'         => 'abc';
    decode_ok 'u3.abc,'         => 'abc';
    decode_ok 'u10.1234567890,' => '1234567890';
    decode_err
      'u02.xy' => 'DecodeUTF8',
      'string with extra leading zero in count';
    decode_err 'u9999.x' => 'DecodeUTF8Trunc', 'string shorter than count';
    decode_ok "u2.\x0A\x0D," => "\x0A\x0D";
    decode_err
      'u00.,' => 'DecodeUTF8',
      'zero-length string with extra leading zero in count';
};

subtest BYTES => sub {
    decode_err 'b23'   => 'DecodeBytes',      'incomplete bytes definition';
    decode_err 'bxxx'  => 'DecodeBytes',      'invalid bytes definition';
    decode_err 'b2.1'  => 'DecodeBytesTrunc', 'bytes not long enough';
    decode_err 'b2.1,' => 'DecodeBytesTerm',  'bytes missing terminator';
    decode_ok $BYTES   => $bytes;
};

subtest LIST => sub {
    decode_err '[' => 'DecodeTrunc', 'unclosed empty list';
    decode_ok '[]' => [];
    decode_err
      '[]anfdldjfh' => 'DecodeTrailing',
      'empty list with trailing garbage';
    decode_ok '[~,~,~,]' => [ undef, undef, undef ];
    decode_ok '[t,f,]' => [ boolean::true, boolean::false ];
    decode_ok '[u0.,u0.,u0.,]'               => [ '',    '',   '' ];
    decode_ok '[i1,i2,i3,]'                  => [ 1,     2,    3 ];
    decode_ok '[u3.asd,u2.xy,' . $UTF8 . ']' => [ 'asd', 'xy', $utf8 ];
    decode_ok '[[u5.Alice,u3.Bob,][i2,i3,~,]~,]' =>
      [ [ 'Alice', 'Bob' ], [ 2, 3, undef ], undef ];
    decode_err '[u0.,' => 'DecodeTrunc', 'unclosed list with content';
    decode_err
      '[u01.a,]' => 'DecodeUTF8',
      'list with string with leading zero in count';
    decode_err '[u-3.,]' => 'DecodeUTF8', 'list with negative-length string';

};

subtest DICT => sub {
    decode_err '{' => 'DecodeTrunc', 'unclosed empty dict';
    decode_err
      '{}foobar' => 'DecodeTrailing',
      'empty dict with trailing garbage';
    decode_ok '{}' => {};
    decode_ok '{' . $BYTES_KEY . $UTF8 . '}' => { $bytes => $utf8 };
    decode_ok '{' . $UTF8_KEY . $BYTES . '}' => { $utf8  => $bytes };
    decode_ok
      '{u3.age:i25,u4.eyes:u4.blue,u5.false:f,u4.true:t,u5.undef:~,}' => {
        'age'   => 25,
        'eyes'  => 'blue',
        'undef' => undef,
        true    => boolean::true,
        false   => boolean::false,
      };
    decode_ok
      '{u8.spam.mp3:{u6.author:u5.Alice,u6.length:i100000,u5.undef:~,}}' =>
      { 'spam.mp3' =>
          { 'author' => 'Alice', 'length' => 100000, 'undef' => undef } };

    decode_err '{~,}'      => 'DecodeKeyType', 'dict key must be UTF8 or BYTES';
    decode_err '{~:}'      => 'DecodeKeyType', 'dict key must be UTF8 or BYTES';
    decode_err '{i1,u0.,}' => 'DecodeKeyType', 'dict key must be UTF8 or BYTES';
    decode_err '{i1:u0.,}' => 'DecodeKeyType', 'dict key must be UTF8 or BYTES';

    decode_err
      '{u3.foo:}' => 'DecodeKeyValue',
      'dict with odd number of elements';
    decode_err '{u1.b:u0.,u1.a:u0.,}' => 'DecodeKeyOrder',     'missorted keys';
    decode_err '{u1.a:u0.,u1.a:u0.,}' => 'DecodeKeyDuplicate', 'duplicate keys';
    decode_err
      '{u0.:' => 'DecodeTrunc',
      'unclosed dict with odd number of elements';
    decode_err '{u0.:u0.,' => 'DecodeTrunc', 'unclosed dict with content';

};

subtest nest_limits => sub {
    decode_ok [ '[u0.,]', 1 ] => [''];  # Accept single list when max_depth is 1
    decode_err [ '[u0.,]', 0 ] => 'DecodeDepth',
      'single list when max_depth is 0';

    # Accept a nested list when max_depth is 2
    decode_ok [ '[[u0.,]]', 2 ] => [ [''] ];
    decode_err [ '[[u0.,]]', 1 ] => 'DecodeDepth',
      'nested list when max_depth is 1';

    # Accept list containing dict when max_depth is 2
    decode_ok [ '[{u1.a:u0.,}]', 2 ] => [ { 'a' => '' } ];

    decode_err [ '[{u1.a:u0.,}]', 1 ] => 'DecodeDepth',
      'dict in list when max_depth is 1';

    # Accept single dict when max_depth is 1
    decode_ok [ '{u1.a:u0.,}', 1 ] => { a => '' };
    decode_err [ '{u1.a:u0.,}', 0 ] => 'DecodeDepth',
      'single dict when max_depth is 0';

    # Accept a nested dict when max_depth is 2
    decode_ok [ '{u1.a:{u1.a:u0.,}}', 2 ] => { a => { a => '' } };
    decode_err [ '{u1.a:{u1.a:u0.,}}', 1 ] => 'DecodeDepth',
      'nested dict when max_depth is 1';

    # Accept dict containing list when max_depth is 2
    decode_ok [ '{u1.a:[u0.,]}', 2 ] => { a => [''] };
    decode_err [ '{u1.a:[u0.,]}', 1 ] => 'DecodeDepth',
      'list in dict when max_depth is 1';

    # Accept dict containing list when max_depth is 2
    decode_ok [ '{u1.a:u0.,u1.b:[u0.,]}', 2 ] => { a => '', b => [''] };
    decode_err [ '{u1.a:u0.,u1.b:[u0.,]}', 1 ] => 'DecodeDepth',
      'list in dict when max_depth is 1';
};

decode_err undef, 'DecodeUsage', 'decode_bifcode2 needs defined';
decode_err [ '[u0.,]', 0, 'arg3' ] => 'DecodeUsage',
  'decode_bifcode2 only takes up to 2 args';
decode_err '' => 'DecodeTrunc', 'empty data';
decode_err $utf8 => 'DecodeUsage',
  'check for utf8 flag';
decode_err '0elwjhrlewjh' => 'Decode', 'complete garbage';

done_testing;
