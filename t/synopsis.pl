#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use lib "$RealBin/lib";
use Bifcode::V2 qw( encode_bifcodeV2 decode_bifcodeV2 force_bifcodeV2 );
use boolean;
use Data::Dumper;
use Path::Tiny;
use Test::Bifcode;
no warnings 'once';

my $str = q{encode_bifcodeV2 {
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

binmode STDOUT, ':raw';
print $bifcode, "\n\n";
print( ( eval $str . ',1' ), "\n\n" );
my $bifcode_file = Path::Tiny->tempfile;
$bifcode_file->spew_raw($bifcode);

my $format      = '15/1 " %2x"' . "\n" . '"    " "%_p"' . "\n" . '"\n"' . "\n";
my $format_file = Path::Tiny->tempfile;
$format_file->spew($format);
system( 'hexdump', '-f', $format_file, $bifcode_file );
