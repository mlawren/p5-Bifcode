use strict;
use warnings;
use lib 'lib';
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use boolean;
use Test::Bifcode::V2;
use Test::More 0.88;    # for done_testing

subtest UNDEF => sub {
    decod_ok '~,' => undef;
};

subtest BOOLEAN => sub {
    decod_ok 't,' => boolean::true;
    decod_ok 'f,' => boolean::false;
};

subtest INTEGER => sub {
    error_ok 'i'           => 'DecodeIntegerTrunc', 'aborted integer';
    error_ok 'i0'          => 'DecodeInteger',      'unterminated integer';
    error_ok 'i,'          => 'DecodeInteger',      'empty integer';
    error_ok 'i341foo382,' => 'DecodeInteger',      'malformed integer';
    decod_ok 'i4,'         => 4;
    decod_ok 'i0,'         => 0;
    decod_ok 'i123456789,' => 123456789;
    decod_ok 'i-10,'       => -10;
    error_ok 'i-0,'        => 'DecodeInteger',      'negative zero integer';
    error_ok 'i123'        => 'DecodeInteger',      'unterminated integer';
    error_ok 'i6,asd' => 'DecodeTrailing', 'integer with trailing garbage';
    error_ok 'i03,'   => 'DecodeInteger',  'integer with leading zero';
    error_ok 'i-03,'  => 'DecodeInteger',  'negative integer with leading zero';
};

subtest REAL => sub {
    error_ok 'r'     => 'DecodeRealTrunc', 'aborted real';
    error_ok 'r0'    => 'DecodeReal',      'aborted real';
    error_ok 'r0.'   => 'DecodeReal',      'aborted real';
    error_ok 'r0.0'  => 'DecodeReal',      'aborted real';
    error_ok 'r0.0e' => 'DecodeReal',      'aborted real';
    error_ok 'r0.e0' => 'DecodeReal',      'aborted real';
    error_ok 'r0e0'  => 'DecodeReal',      'aborted real';
    decod_ok 'r0.0e0,'  => '0.0e0';
    decod_ok 'r4.1e-2,' => '4.1e-2';
    error_ok 'r-0.0e0,' => 'DecodeReal', 'non-zero exponent for 0.0 real';
    error_ok 'r0.0e-1,' => 'DecodeReal', 'non-zero exponent for 0.0 real';
};

subtest UTF8 => sub {
    error_ok
      'u0.,u0.' => 'DecodeTrailing',
      'data past end of first correct encode_bifcode\'d string';
    error_ok 'u1.'  => 'DecodeUTF8Trunc', 'string longer than data';
    error_ok 'u1.1' => 'DecodeUTF8Term',  'string missing terminator';
    error_ok
      'u35208734823ljdahflajhdf' => 'DecodeUTF8',
      'garbage looking vaguely like a string, with large count';
    error_ok
      'u2.abfdjslhfld' => 'DecodeUTF8Term',
      'string with trailing garbage';
    decod_ok $UTF8             => $utf8;
    decod_ok 'u0.,'            => '';
    decod_ok 'u3.abc,'         => 'abc';
    decod_ok 'u3.abc,'         => 'abc';
    decod_ok 'u10.1234567890,' => '1234567890';
    error_ok
      'u02.xy' => 'DecodeUTF8',
      'string with extra leading zero in count';
    error_ok 'u9999.x' => 'DecodeUTF8Trunc', 'string shorter than count';
    decod_ok "u2.\x0A\x0D," => "\x0A\x0D";
    error_ok
      'u00.,' => 'DecodeUTF8',
      'zero-length string with extra leading zero in count';
};

subtest BYTES => sub {
    error_ok 'b23'   => 'DecodeBytes',      'incomplete bytes definition';
    error_ok 'bxxx'  => 'DecodeBytes',      'invalid bytes definition';
    error_ok 'b2.1'  => 'DecodeBytesTrunc', 'bytes not long enough';
    error_ok 'b2.1,' => 'DecodeBytesTerm',  'bytes missing terminator';
    decod_ok $BYTES  => $bytes;
};

subtest LIST => sub {
    error_ok '[' => 'DecodeTrunc', 'unclosed empty list';
    decod_ok '[]' => [];
    error_ok
      '[]anfdldjfh' => 'DecodeTrailing',
      'empty list with trailing garbage';
    decod_ok '[~,~,~,]' => [ undef, undef, undef ];
    decod_ok '[t,f,]' => [ boolean::true, boolean::false ];
    decod_ok '[u0.,u0.,u0.,]'               => [ '',    '',   '' ];
    decod_ok '[i1,i2,i3,]'                  => [ 1,     2,    3 ];
    decod_ok '[u3.asd,u2.xy,' . $UTF8 . ']' => [ 'asd', 'xy', $utf8 ];
    decod_ok '[[u5.Alice,u3.Bob,][i2,i3,~,]~,]' =>
      [ [ 'Alice', 'Bob' ], [ 2, 3, undef ], undef ];
    error_ok '[u0.,' => 'DecodeTrunc', 'unclosed list with content';
    error_ok
      '[u01.a,]' => 'DecodeUTF8',
      'list with string with leading zero in count';
    error_ok '[u-3.,]' => 'DecodeUTF8', 'list with negative-length string';

};

subtest DICT => sub {
    error_ok '{'        => 'DecodeTrunc',    'unclosed empty dict';
    error_ok '{}foobar' => 'DecodeTrailing', 'empty dict with trailing garbage';
    decod_ok '{}'       => {};
    decod_ok '{' . $BYTES . $UTF8 . '}' => { $bytes => $utf8 };
    decod_ok '{' . $UTF8 . $BYTES . '}' => { $utf8  => $bytes };
    decod_ok '{u3.age,i25,u4.eyes,u4.blue,u5.false,f,u4.true,t,u5.undef,~,}' =>
      {
        'age'   => 25,
        'eyes'  => 'blue',
        'undef' => undef,
        true    => boolean::true,
        false   => boolean::false,
      };
    decod_ok
      '{u8.spam.mp3,{u6.author,u5.Alice,u6.length,i100000,u5.undef,~,}}' =>
      { 'spam.mp3' =>
          { 'author' => 'Alice', 'length' => 100000, 'undef' => undef } };

    error_ok '{~,}' => 'DecodeKeyType', 'dict key cannot be undef';
    error_ok
      '{u3.foo,}' => 'DecodeKeyValue',
      'dict with odd number of elements';
    error_ok '{I1,u0.,}' => 'DecodeKeyType', 'dict with integer key';
    error_ok '{u1.b,u0.,u1.a,u0.,}' => 'DecodeKeyOrder',     'missorted keys';
    error_ok '{u1.a,u0.,u1.a,u0.,}' => 'DecodeKeyDuplicate', 'duplicate keys';
    error_ok
      '{u0.,' => 'DecodeTrunc',
      'unclosed dict with odd number of elements';
    error_ok '{u0.,u0.,' => 'DecodeTrunc', 'unclosed dict with content';

};

subtest nest_limits => sub {
    decod_ok [ '[u0.,]', 1 ] => [''];   # Accept single list when max_depth is 1
    error_ok [ '[u0.,]', 0 ] => 'DecodeDepth',
      'single list when max_depth is 0';

    # Accept a nested list when max_depth is 2
    decod_ok [ '[[u0.,]]', 2 ] => [ [''] ];
    error_ok [ '[[u0.,]]', 1 ] => 'DecodeDepth',
      'nested list when max_depth is 1';

    # Accept list containing dict when max_depth is 2
    decod_ok [ '[{u1.a,u0.,}]', 2 ] => [ { 'a' => '' } ];

    error_ok [ '[{u1.a,u0.,}]', 1 ] => 'DecodeDepth',
      'dict in list when max_depth is 1';

    # Accept single dict when max_depth is 1
    decod_ok [ '{u1.a,u0.,}', 1 ] => { a => '' };
    error_ok [ '{u1.a,u0.,}', 0 ] => 'DecodeDepth',
      'single dict when max_depth is 0';

    # Accept a nested dict when max_depth is 2
    decod_ok [ '{u1.a,{u1.a,u0.,}}', 2 ] => { a => { a => '' } };
    error_ok [ '{u1.a,{u1.a,u0.,}}', 1 ] => 'DecodeDepth',
      'nested dict when max_depth is 1';

    # Accept dict containing list when max_depth is 2
    decod_ok [ '{u1.a,[u0.,]}', 2 ] => { a => [''] };
    error_ok [ '{u1.a,[u0.,]}', 1 ] => 'DecodeDepth',
      'list in dict when max_depth is 1';

    # Accept dict containing list when max_depth is 2
    decod_ok [ '{u1.a,u0.,u1.b,[u0.,]}', 2 ] => { a => '', b => [''] };
    error_ok [ '{u1.a,u0.,u1.b,[u0.,]}', 1 ] => 'DecodeDepth',
      'list in dict when max_depth is 1';
};

error_ok undef, 'DecodeUsage', 'decode_bifcode needs defined';
error_ok [ '[u0.,]', 0, 'arg3' ] => 'DecodeUsage',
  'decode_bifcode only takes up to 2 args';
error_ok '' => 'DecodeTrunc', 'empty data';
error_ok $utf8 => 'DecodeUsage',
  'check for utf8 flag';
error_ok '0elwjhrlewjh' => 'Decode', 'complete garbage';

done_testing;
