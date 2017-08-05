use strict;
use warnings;
use utf8;
use Test::More 0.88;    # for done_testing
use Test::Differences;
use Bifcode 'decode_bifcode';
require bytes;

my $utf8 =
'ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ';
utf8::encode( my $utf8_bytes = $utf8 );
my $utf8_length  = bytes::length($utf8_bytes);
my $utf8_bifcode = $utf8_length . ':' . $utf8_bytes;

my $data         = pack( 's<', 255 );
my $data_length  = bytes::length($data);
my $data_bifcode = $data_length . ';' . $data;

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

error_ok
  '0:0:' => qr/\Atrailing garbage at 2\b/,
  'data past end of first correct encode_bifcode\'d string';
error_ok 'i'  => qr/\Aunexpected end of data at 1\b/, 'aborted integer';
error_ok 'i0' => qr/\Amalformed integer data at 1\b/, 'unterminated integer';
error_ok 'i,' => qr/\Amalformed integer data at 1\b/, 'empty integer';
error_ok
  'i341foo382,' => qr/\Amalformed integer data at 1\b/,
  'malformed integer';
decod_ok '~'           => undef;
decod_ok 'T'           => $Bifcode::TRUE;
decod_ok 'F'           => $Bifcode::FALSE;
decod_ok 'i4,'         => 4;
decod_ok 'i0,'         => 0;
decod_ok 'i123456789,' => 123456789;
decod_ok 'i-10,'       => -10;
error_ok 'i-0,' => qr/\Amalformed integer data at 1\b/, 'negative zero integer';
error_ok 'i123' => qr/\Amalformed integer data at 1\b/, 'unterminated integer';
error_ok ''     => qr/\Aunexpected end of data at 0/,   'empty data';
error_ok
  '1:' => qr/\Aunexpected end of string data starting at 2\b/,
  'string longer than data';
error_ok
  'i6,asd' => qr/\Atrailing garbage at 3\b/,
  'integer with trailing garbage';
error_ok
  '35208734823ljdahflajhdf' => qr/\Agarbage at 0/,
  'garbage looking vaguely like a string, with large count';
error_ok
  '2:abfdjslhfld' => qr/\Atrailing garbage at 4\b/,
  'string with trailing garbage';
error_ok '2:' . $utf8 => qr/\Adecode_bifcode: only accepts bytes\b/,
  'check for utf8 flag';
decod_ok '0:'            => '';
decod_ok '3:abc'         => 'abc';
decod_ok '3:abc'         => 'abc';
decod_ok '10:1234567890' => '1234567890';
decod_ok $data_bifcode   => \$data;
decod_ok $utf8_bifcode   => $utf8;
error_ok
  '02:xy' => qr/\Amalformed string length at 0\b/,
  'string with extra leading zero in count';
error_ok '[' => qr/\Aunexpected end of data at 1\b/, 'unclosed empty list';
decod_ok '[]' => [];
error_ok
  '[]anfdldjfh' => qr/\Atrailing garbage at 2\b/,
  'empty list with trailing garbage';
decod_ok '[~~~]' => [ undef, undef, undef ];
decod_ok '[TF]' => [ $Bifcode::TRUE, $Bifcode::FALSE ];
decod_ok '[0:0:0:]' => [ '', '', '' ];
error_ok 'relwjhrlewjh' => qr/\Agarbage at 0/, 'complete garbage';
decod_ok '[i1,i2,i3,]'                      => [ 1,     2,    3 ];
decod_ok '[3:asd2:xy' . $utf8_bifcode . ']' => [ 'asd', 'xy', $utf8 ];
decod_ok '[[5:Alice3:Bob][i2,i3,~]~]' =>
  [ [ 'Alice', 'Bob' ], [ 2, 3, undef ], undef ];
error_ok '{' => qr/\Aunexpected end of data at 1\b/, 'unclosed empty dict';
error_ok
  '{}foobar' => qr/\Atrailing garbage at 2\b/,
  'empty dict with trailing garbage';
decod_ok '{}' => {};
decod_ok '{' . $data_bifcode . $utf8_bifcode . '}' => { $data => $utf8 };
decod_ok '{' . $utf8_bifcode . $data_bifcode . '}' => { $utf8 => \$data };
decod_ok '{3:agei25,4:eyes4:blue5:falseF4:trueT5:undef~}' => {
    'age'   => 25,
    'eyes'  => 'blue',
    'undef' => undef,
    true    => $Bifcode::TRUE,
    false   => $Bifcode::FALSE,
};
decod_ok '{8:spam.mp3{6:author5:Alice6:lengthi100000,5:undef~}}' =>
  { 'spam.mp3' =>
      { 'author' => 'Alice', 'length' => 100000, 'undef' => undef } };
error_ok
  '{~}' => qr/\Adict key is not a string at 1\b/,
  'dict key cannot be undef';
error_ok
  '{3:foo}' => qr/\Adict key is missing value at 7\b/,
  'dict with odd number of elements';
error_ok
  '{i1,0:}' => qr/\Adict key is not a string at 1/,
  'dict with integer key';
error_ok
  '{1:b0:1:a0:}' => qr/\Adict key not in sort order at 9/,
  'missorted keys';
error_ok '{1:a0:1:a0:}' => qr/\Aduplicate dict key at 9/, 'duplicate keys';
error_ok
  'i03,' => qr/\Amalformed integer data at 1/,
  'integer with leading zero';
error_ok
  '[01:a]' => qr/\Amalformed string length at 1/,
  'list with string with leading zero in count';
error_ok
  '9999:x' => qr/\Aunexpected end of string data starting at 5/,
  'string shorter than count';
error_ok
  '[0:' => qr/\Aunexpected end of data at 3/,
  'unclosed list with content';
error_ok
  '{0:0:' => qr/\Aunexpected end of data at 5/,
  'unclosed dict with content';
error_ok
  '{0:' => qr/\Aunexpected end of data at 3/,
  'unclosed dict with odd number of elements';
error_ok
  '00:' => qr/\Amalformed string length at 0/,
  'zero-length string with extra leading zero in count';
error_ok
  '[-3:]' => qr/\Amalformed string length at 1/,
  'list with negative-length string';
error_ok
  'i-03,' => qr/\Amalformed integer data at 1/,
  'negative integer with leading zero';
decod_ok "2:\x0A\x0D" => "\x0A\x0D";

decod_ok [ '{1:a0:}', 1 ] => { a => '' }
  ,    # Accept single dict when max_depth is 1
  error_ok [ '{1:a0:}', 0 ] => qr/\Anesting depth exceeded at 1/,
  'single dict when max_depth is 0';
decod_ok [ '{1:a{1:a0:}}', 2 ] => { a => { a => '' } }
  ,    # Accept a nested dict when max_depth is 2
  error_ok [ '{1:a{1:a0:}}', 1 ] => qr/\Anesting depth exceeded at 5/,
  'nested dict when max_depth is 1';
decod_ok [ '[0:]', 1 ] => [''],    # Accept single list when max_depth is 1
  error_ok [ '[0:]', 0 ] => qr/\Anesting depth exceeded at 1/,
  'single list when max_depth is 0';
decod_ok [ '[[0:]]', 2 ] => [ [''] ], # Accept a nested list when max_depth is 2
  error_ok [ '[[0:]]', 1 ] => qr/\Anesting depth exceeded at 2/,
  'nested list when max_depth is 1';
decod_ok [ '{1:a[0:]}', 2 ] => { a => [''] }
  ,    # Accept dict containing list when max_depth is 2
  error_ok [ '{1:a[0:]}', 1 ] => qr/\Anesting depth exceeded at 5/,
  'list in dict when max_depth is 1';
decod_ok [ '[{1:a0:}]', 2 ] => [ { 'a' => '' } ]
  ,    # Accept list containing dict when max_depth is 2
  error_ok [ '[{1:a0:}]', 1 ] => qr/\Anesting depth exceeded at 2/,
  'dict in list when max_depth is 1';
decod_ok [ '{1:a0:1:b[0:]}', 2 ] => { a => '', b => [''] }
  ,    # Accept dict containing list when max_depth is 2
  error_ok [ '{1:a0:1:b[0:]}', 1 ] => qr/\Anesting depth exceeded at 10/,
  'list in dict when max_depth is 1';

done_testing;
