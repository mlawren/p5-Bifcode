#!/usr/bin/env perl
use Test2::V0;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use boolean;
use Bifcode2 qw( encode_bifcode2 decode_bifcode2 force_bifcode2 );
use Path::Tiny;
use Term::Table;
use Math::BigInt;

my $struct = q{{
    bools   => [ boolean::false, boolean::true, ],
    bytes   => \pack( 's<',       255 ),
    integer => 25,
    real    => 1.25e-5,
    null    => undef,
    utf8    => "Ελύτη",
}
};

my $ref      = eval $struct;
my $bifcode2 = encode_bifcode2 $ref;

note 'my $bifcode2 = encode_bifcode2 ' . $struct;
note $bifcode2;

like( $bifcode2, qr/^{/, 'bifcode2 hash' );

my $bifcode2_file = Path::Tiny->tempfile;
$bifcode2_file->spew_raw($bifcode2);

my $format      = '15/1 " %2x"' . "\n" . '"    " "%_p"' . "\n" . '"\n"' . "\n";
my $format_file = Path::Tiny->tempfile;
$format_file->spew($format);
open my $fh, '-|', 'hexdump', '-f', $format_file, $bifcode2_file;
note $_ while <$fh>;

my $table_src = Term::Table->new(
    header => [ 'Type', 'Perl', 'Bifcode2' ],
    rows   => [
        [ 'UNDEF',   'undef',          encode_bifcode2(undef) ],
        [ 'TRUE',    'boolean::true',  encode_bifcode2(true) ],
        [ 'FALSE',   'boolean::false', encode_bifcode2(false) ],
        [ 'INTEGER', -1,               encode_bifcode2(-1) ],
        [ 'INTEGER', 0,                encode_bifcode2(0) ],
        [ 'INTEGER', 1,                encode_bifcode2(1) ],

        #    [ 'REAL',    '0.0', encode_bifcode2('0.0') ],
        [ 'REAL', 3.1415,               encode_bifcode2(3.1415) ],
        [ 'REAL', 1.380649e-23,         encode_bifcode2(1.380649e-23) ],
        [ 'INF',  'use bignum;  inf()', encode_bifcode2( Math::BigInt->binf ) ],
        [
            'NEGINF',
            q{use bignum; -inf()},
            encode_bifcode2( Math::BigInt->binf('-') )
        ],

        #        [ 'RATIONAL', -inf,               encode_bifcode2(-inf) ],
        [ 'INTEGER', 0, encode_bifcode2(0) ],
        [
            'BYTES', q[$TWO_BYTE_STR],
            encode_bifcode2( \pack( 's<', 255 ) ) =~ s/([.:]).*,/${1}��,/r
        ],
        [
            'UTF8',
            q{'MIXΣD ƬΣXƬ'},
            encode_bifcode2('MIXΣD ƬΣXƬ') =~ s/([.:])(.*),/${1}MIXΣD ƬΣXƬ,/r
        ],
        [ 'ARRAY', q{[ 'one', 'two' ]}, encode_bifcode2( [ 'one', 'two' ] ) ],
        [ 'DICT', q[{ key => 'value'}], encode_bifcode2( { key => 'value' } ) ],

    ],
);

my $table = join( "\n", $table_src->render, '' );

note($table);

done_testing();
