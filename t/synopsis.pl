#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use lib "$RealBin/lib";
use Bifcode qw( encode_bifcode decode_bifcode force_bifcode );
use boolean;
use Data::Dumper 'Dumper';
use Path::Tiny;
use Test::Bifcode;
use Text::Table::Tiny 0.04 qw/ generate_table /;
no warnings 'once';

my $str = q{encode_bifcode {
    bools   => [ boolean::false, boolean::true, ],
    bytes   => \pack( 's<',       255 ),
    integer => 25,
    float   => 1.25e-5,
    undef   => undef,
    utf8    => "Ελύτη",
};
};

binmode STDOUT, ':utf8';
print 'my $bifcode = ' . $str;
my $bifcode = eval $str;

print $bifcode, "\n\n";
my $bifcode_file = Path::Tiny->tempfile;
$bifcode_file->spew_raw($bifcode);

my $format      = '12/1 " %2x"' . "\n" . '"    " "%_p"' . "\n" . '"\n"' . "\n";
my $format_file = Path::Tiny->tempfile;
$format_file->spew($format);
system( 'hexdump', '-f', $format_file, $bifcode_file );

use constant TYPE    => 0;
use constant PERL    => 1;
use constant DISPLAY => 2;

$Data::Dumper::Indent = 0;

my @items = (
    [ 'UNDEF',   undef ],
    [ 'TRUE',    true,  'boolean::true' ],
    [ 'FALSE',   false, 'boolean::false' ],
    [ 'INTEGER', -1 ],
    [ 'INTEGER', 0 ],
    [ 'INTEGER', 1 ],
    [ 'REAL',    '0.0' ],
    [ 'REAL',    3.1415 ],
    [ 'BYTES',   \pack( 's<', 255 ), q{pack( 's<', 255 )} ],
    [ 'UTF8',    'MIXΣD ƬΣXƬ',       q{'MIXΣD ƬΣXƬ'} ],
    [ 'ARRAY',   [ 'one', 'two' ] ],
    [ 'DICT',    { key => 'value' } ],
);

my $rows = [
    [ 'Type', 'Perl', 'Bifcode' ],
    map {
        [
            $_->[TYPE],
            $_->[DISPLAY] // ( Dumper( $_->[PERL] ) =~ s/(\$VAR1 = )|;//gr ),
            encode_bifcode( $_->[PERL] )
        ]
    } @items
];

print generate_table(
    rows       => $rows,
    header_row => 1
) =~ s/(B2.*,)/$1 /r;
print "\n";
