#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use lib "$RealBin/lib";
use Bifcode2 qw( encode_bifcode2 decode_bifcode2 force_bifcode2 );
use boolean;
use Data::Dumper 'Dumper';
use Path::Tiny;
use Test::Bifcode;
use Text::Table::Tiny 0.04 qw/ generate_table /;

no warnings 'once';

my $str = q{encode_bifcode2 {
    bools   => [ boolean::false, boolean::true, ],
    bytes   => \pack( 's<',       255 ),
    integer => 25,
    real    => 1.25e-5,
    null    => undef,
    utf8    => "Ελύτη",
}
};

binmode STDOUT, ':utf8';
print 'my $bifcode = ' . $str;
my $bifcode = eval $str;

binmode STDOUT, ':bytes';
print $bifcode, "\n\n";
print( ( eval $str . ',1' ), "\n\n" );
my $bifcode_file = Path::Tiny->tempfile;
$bifcode_file->spew_raw($bifcode);

my $format      = '15/1 " %2x"' . "\n" . '"    " "%_p"' . "\n" . '"\n"' . "\n";
my $format_file = Path::Tiny->tempfile;
$format_file->spew($format);
system( 'hexdump', '-f', $format_file, $bifcode_file );

use constant TYPE    => 0;
use constant PERL    => 1;
use constant DISPLAY => 2;

$Data::Dumper::Indent = 0;
use Encode 'encode';
my @items = ();

my $rows = [
    [ 'Type',    'Perl',           'Bifcode' ],
    [ 'UNDEF',   'undef',          encode_bifcode2(undef) ],
    [ 'TRUE',    'boolean::true',  encode_bifcode2(true) ],
    [ 'FALSE',   'boolean::false', encode_bifcode2(false) ],
    [ 'INTEGER', -1,               encode_bifcode2(-1) ],
    [ 'INTEGER', 0,                encode_bifcode2(0) ],
    [ 'INTEGER', 1,                encode_bifcode2(1) ],

    #    [ 'REAL',    '0.0', encode_bifcode2('0.0') ],
    [ 'REAL',  3.1415,                encode_bifcode2(3.1415) ],
    [ 'BYTES', q[\pack( 's<', 255 )], encode_bifcode2( pack( 's<', 255 ) ) ],
    [
        'UTF8', encode( 'UTF-8', q{'MIXΣD ƬΣXƬ'} ),
        encode_bifcode2('MIXΣD ƬΣXƬ')
    ],
    [ 'ARRAY', q{[ 'one', 'two' ]},  encode_bifcode2( [ 'one', 'two' ] ) ],
    [ 'DICT',  q[{ key => 'value'}], encode_bifcode2( { key => 'value' } ) ],
];

my $T     = encode( 'UTF-8', 'Ƭ' );
my $table = generate_table(
    rows       => $rows,
    header_row => 1
);
$table =~ s/$T'/$T'    /;
$table =~ s/$T,/$T,    /;
$table =~ s/(b2.*, )/$1 /;

print $table. "\n";
