use strict;
use warnings;
use utf8;

use Test::More 0.88;    # for done_testing
use Test::Differences;
use Cencode 'cdecode';
use Unicode::UTF8 'encode_utf8';

my $utf8   = 'ß';
my $bytes  = encode_utf8($utf8);
my $length = length($bytes);
my $cstr   = $length . ':' . $bytes;

sub un {
    my ($frozen) = @_;
    local $, = ', ';
    return 'ARRAY' eq ref $frozen
      ? ( "decode [@$frozen]", cdecode @$frozen )
      : ( "decode '$frozen'", cdecode $frozen );
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
  'data past end of first correct cencoded string';
error_ok 'i'  => qr/\Aunexpected end of data at 1\b/, 'aborted integer';
error_ok 'i0' => qr/\Amalformed integer data at 1\b/, 'unterminated integer';
error_ok 'i,' => qr/\Amalformed integer data at 1\b/, 'empty integer';
error_ok
  'i341foo382,' => qr/\Amalformed integer data at 1\b/,
  'malformed integer';
decod_ok '~'           => undef;
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
error_ok '2:' . $utf8 => qr/\Acdecode: only accepts bytes\b/,
  'check for utf8 flag';
decod_ok '0:'            => '';
decod_ok $cstr           => $utf8;
decod_ok '3:abc'         => 'abc';
decod_ok '3:abc'         => 'abc';
decod_ok '10:1234567890' => '1234567890';
error_ok
  '02:xy' => qr/\Amalformed string length at 0\b/,
  'string with extra leading zero in count';
error_ok 'l' => qr/\Aunexpected end of data at 1\b/, 'unclosed empty list';
decod_ok 'l,' => [];
error_ok
  'l,anfdldjfh' => qr/\Atrailing garbage at 2\b/,
  'empty list with trailing garbage';
decod_ok 'l~~~,'    => [ undef, undef, undef ];
decod_ok 'l0:0:0:,' => [ '',    '',    '' ];
error_ok 'relwjhrlewjh' => qr/\Agarbage at 0/, 'complete garbage';
decod_ok 'li1,i2,i3,,'              => [ 1,     2,    3 ];
decod_ok 'l3:asd2:xy' . $cstr . ',' => [ 'asd', 'xy', $utf8 ];
decod_ok 'll5:Alice3:Bob,li2,i3,~,~,' =>
  [ [ 'Alice', 'Bob' ], [ 2, 3, undef ], undef ];
error_ok 'd' => qr/\Aunexpected end of data at 1\b/, 'unclosed empty dict';
error_ok
  'd,foobar' => qr/\Atrailing garbage at 2\b/,
  'empty dict with trailing garbage';
decod_ok 'd,' => {};
decod_ok 'd' . $cstr . $cstr . ',' => { $utf8 => $utf8 };
decod_ok 'd3:agei25,4:eyes4:blue5:undef~,' =>
  { 'age' => 25, 'eyes' => 'blue', 'undef' => undef };
decod_ok 'd8:spam.mp3d6:author5:Alice6:lengthi100000,5:undef~,,' =>
  { 'spam.mp3' =>
      { 'author' => 'Alice', 'length' => '100000', 'undef' => undef } };
error_ok
  'd~,' => qr/\Adict key is not a string at 1\b/,
  'dict key cannot be undef';
error_ok
  'd3:foo,' => qr/\Adict key is missing value at 7\b/,
  'dict with odd number of elements';
error_ok
  'di1,0:,' => qr/\Adict key is not a string at 1/,
  'dict with integer key';
error_ok
  'd1:b0:1:a0:,' => qr/\Adict key not in sort order at 9/,
  'missorted keys';
error_ok 'd1:a0:1:a0:,' => qr/\Aduplicate dict key at 9/, 'duplicate keys';
error_ok
  'i03,' => qr/\Amalformed integer data at 1/,
  'integer with leading zero';
error_ok
  'l01:a,' => qr/\Amalformed string length at 1/,
  'list with string with leading zero in count';
error_ok
  '9999:x' => qr/\Aunexpected end of string data starting at 5/,
  'string shorter than count';
error_ok
  'l0:' => qr/\Aunexpected end of data at 3/,
  'unclosed list with content';
error_ok
  'd0:0:' => qr/\Aunexpected end of data at 5/,
  'unclosed dict with content';
error_ok
  'd0:' => qr/\Aunexpected end of data at 3/,
  'unclosed dict with odd number of elements';
error_ok
  '00:' => qr/\Amalformed string length at 0/,
  'zero-length string with extra leading zero in count';
error_ok
  'l-3:,' => qr/\Amalformed string length at 1/,
  'list with negative-length string';
error_ok
  'i-03,' => qr/\Amalformed integer data at 1/,
  'negative integer with leading zero';
decod_ok "2:\x0A\x0D" => "\x0A\x0D";

decod_ok [ 'd1:a0:,', 1 ] => { a => '' }
  ,    # Accept single dict when max_depth is 1
  error_ok [ 'd1:a0:,', 0 ] => qr/\Anesting depth exceeded at 1/,
  'single dict when max_depth is 0';
decod_ok [ 'd1:ad1:a0:,,', 2 ] => { a => { a => '' } }
  ,    # Accept a nested dict when max_depth is 2
  error_ok [ 'd1:ad1:a0:,,', 1 ] => qr/\Anesting depth exceeded at 5/,
  'nested dict when max_depth is 1';
decod_ok [ 'l0:,', 1 ] => [''],    # Accept single list when max_depth is 1
  error_ok [ 'l0:,', 0 ] => qr/\Anesting depth exceeded at 1/,
  'single list when max_depth is 0';
decod_ok [ 'll0:,,', 2 ] => [ [''] ], # Accept a nested list when max_depth is 2
  error_ok [ 'll0:,,', 1 ] => qr/\Anesting depth exceeded at 2/,
  'nested list when max_depth is 1';
decod_ok [ 'd1:al0:,,', 2 ] => { a => [''] }
  ,    # Accept dict containing list when max_depth is 2
  error_ok [ 'd1:al0:,,', 1 ] => qr/\Anesting depth exceeded at 5/,
  'list in dict when max_depth is 1';
decod_ok [ 'ld1:a0:,,', 2 ] => [ { 'a' => '' } ]
  ,    # Accept list containing dict when max_depth is 2
  error_ok [ 'ld1:a0:,,', 1 ] => qr/\Anesting depth exceeded at 2/,
  'dict in list when max_depth is 1';
decod_ok [ 'd1:a0:1:bl0:,,', 2 ] => { a => '', b => [''] }
  ,    # Accept dict containing list when max_depth is 2
  error_ok [ 'd1:a0:1:bl0:,,', 1 ] => qr/\Anesting depth exceeded at 10/,
  'list in dict when max_depth is 1';

done_testing;
