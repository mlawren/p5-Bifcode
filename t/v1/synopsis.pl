#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/lib";
use Bifcode::V1 qw( encode_bifcode decode_bifcode force_bifcode );
use boolean;
use Data::Dumper;
use Path::Tiny;
use Test::Bifcode;
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

binmode STDOUT;
print $bifcode, "\n\n";
my $bifcode_file = Path::Tiny->tempfile;
$bifcode_file->spew_raw($bifcode);

my $format      = '12/1 " %2x"' . "\n" . '"    " "%_p"' . "\n" . '"\n"' . "\n";
my $format_file = Path::Tiny->tempfile;
$format_file->spew($format);
system( 'hexdump', '-f', $format_file, $bifcode_file );
