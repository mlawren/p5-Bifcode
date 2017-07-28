use strict;
use warnings;

use Test::More 0.88;    # for done_testing
use Test::Differences;
use Cencode 'cencode';

sub enc_ok {
    my ( $frozen, $thawed ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff cencode($thawed), $frozen, "encode $frozen";
}

enc_ok '~'                        => undef;
enc_ok 'i4,'                      => 4;
enc_ok 'i0,'                      => 0;
enc_ok 'i-10,'                    => -10;
enc_ok 'i12345678901234567890,'   => '12345678901234567890';
enc_ok '0:'                       => '';
enc_ok '3:abc'                    => 'abc';
enc_ok '10:1234567890'            => \'1234567890';
enc_ok 'l,'                       => [];
enc_ok 'li1,i2,~,'                => [ 1, 2, undef ];
enc_ok 'll5:Alice3:Bob,li2,i3,,,' => [ [ 'Alice', 'Bob' ], [ 2, 3 ] ];
enc_ok 'd,'                       => {};
enc_ok 'd3:agei25,4:eyes4:blue5:undef~,' =>
  { 'age' => 25, 'eyes' => 'blue', 'undef' => undef };
enc_ok 'd8:spam.mp3d6:author5:Alice6:lengthi100000,5:undef~,,' =>
  { 'spam.mp3' => { 'author' => 'Alice', 'length' => 100000, 'undef' => undef }
  };

done_testing;
