#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Bifcode qw( encode_bifcode decode_bifcode force_bifcode );
use Data::Dumper;
use Path::Tiny;
no warnings 'once';

my $bifcode = encode_bifcode {
    bools   => [ $Bifcode::FALSE, $Bifcode::TRUE, ],
    bytes   => \pack( 's<',       255 ),
    integer => 25,
    undef   => undef,
    utf8    => "\x{df}",
};

my $bifcode_file = Path::Tiny->tempfile;
$bifcode_file->spew_raw($bifcode);

my $format      = '12/1 " %2x"' . "\n" . '"\t" "%_p"' . "\n" . '"\n"';
my $format_file = Path::Tiny->tempfile;
$format_file->spew($format);
system( 'hexdump', '-f', $format_file, $bifcode_file );
