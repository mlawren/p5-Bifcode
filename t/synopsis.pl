#!/usr/bin/env perl
use Test2::V0;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use boolean;
use Bifcode qw( encode_bifcode decode_bifcode force_bifcode );
use Path::Tiny;
use Term::Table;

my $struct = q{{
    bools   => [ boolean::false, boolean::true, ],
    bytes   => \pack( 's<',       255 ),
    integer => 25,
    real    => 1.25e-5,
    null    => undef,
    utf8    => "Ελύτη",
}
};

my $ref     = eval $struct;
my $bifcode = encode_bifcode $ref;

note 'my $bifcode = encode_bifcode ' . $struct;
note $bifcode;

like( $bifcode, qr/^{/, 'bifcode hash' );

my $bifcode_file = Path::Tiny->tempfile;
$bifcode_file->spew_raw($bifcode);

my $format      = '15/1 " %2x"' . "\n" . '"    " "%_p"' . "\n" . '"\n"' . "\n";
my $format_file = Path::Tiny->tempfile;
$format_file->spew($format);
open my $fh, '-|', 'hexdump', '-f', $format_file, $bifcode_file;
note $_ while <$fh>;

my $table_src = Term::Table->new(
    header => [ 'Type', 'Perl', 'Bifcode' ],
    rows   => [
        [ 'UNDEF',   'undef',          encode_bifcode(undef) ],
        [ 'TRUE',    'boolean::true',  encode_bifcode(true) ],
        [ 'FALSE',   'boolean::false', encode_bifcode(false) ],
        [ 'INTEGER', -1,               encode_bifcode(-1) ],
        [ 'INTEGER', 0,                encode_bifcode(0) ],
        [ 'INTEGER', 1,                encode_bifcode(1) ],

        #    [ 'REAL',    '0.0', encode_bifcode('0.0') ],
        [ 'REAL', 3.1415,       encode_bifcode(3.1415) ],
        [ 'REAL', 1.380649e-23, encode_bifcode(1.380649e-23) ],
        [
            'BYTES', q[$TWO_BYTE_STR],
            encode_bifcode( \pack( 's<', 255 ) ) =~ s/([.:]).*,/${1}��,/r
        ],
        [
            'UTF8',
            q{'MIXΣD ƬΣXƬ'},
            encode_bifcode('MIXΣD ƬΣXƬ') =~ s/([.:])(.*),/${1}MIXΣD ƬΣXƬ,/r
        ],
        [ 'ARRAY', q{[ 'one', 'two' ]},  encode_bifcode( [ 'one', 'two' ] ) ],
        [ 'DICT',  q[{ key => 'value'}], encode_bifcode( { key => 'value' } ) ],

    ],
);

my $table = join( "\n", $table_src->render, '' );

note($table);

done_testing();
