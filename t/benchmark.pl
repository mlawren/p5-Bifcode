#!/usr/bin/env perl
use strict;
use warnings;
require bytes;
use lib 'lib';
use utf8;
use boolean;
use Benchmark qw(cmpthese);
use Bencode   ();
use Bifcode   ();
use Bifcode   ();
use Data::Dumper;
use Compress::Zlib;
use JSON::PP   ();
use JSON::Tiny ();
use Text::Diff 'diff';
use YAML::XS ();

my $size   = 30;
my $rounds = 1000;

my $raw = join(
    '', map s{\s+}{}gr,
    do { local $/; scalar <DATA> }
);
my $png = pack 'H*', $raw;

my $data = [
    map {
        {
            #    bytes => pack( 's<', 255 ),
            bytes   => $png,
            bools   => [ false, true, ],
            integer => $_,
            undef   => undef,
            utf8    => 'ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ',
        }

    } 1 .. $size
];

my $xdata = [
    {
        '_'                     => 'begin_change',
        'mtime'                 => '1438693456000',
        'author_contact'        => 'mark+perl@rekudos.net',
        'mtimetz'               => 7200000,
        'author_contact_method' => 'email',
        'author'                => 'Mark Lawrence',
        'lang'                  => 'en',
        'author_shortname'      => 'ML',
        'parent_uuid'           => undef
    },
    {
        'shortname'                   => 'ML',
        'default_contact_method_uuid' => undef,
        'bill'                        => 1,
        '_uuid'        => 'f1b417064a8a4e0ee92cb6270be87d3b460d677d',
        '_'            => 'new_identity',
        'contact_uuid' => undef,
        'name'         => 'Mark Lawrence'
    },
    {
        'bill'          => 1,
        'identity_uuid' => 'f1b417064a8a4e0ee92cb6270be87d3b460d677d',
        '_uuid'         => 'acf522ee6a4fcb28746fad2774a5b7d9b905ef75',
        'mvalue'        => 'mark+perl@rekudos.net',
        'method'        => 'email',
        '_'             => 'new_identity_contact_method'
    },
    {
        'uuid'         => 'f1b417064a8a4e0ee92cb6270be87d3b460d677d',
        '_'            => 'update_identity',
        'name'         => undef,
        'contact_uuid' => 'f1b417064a8a4e0ee92cb6270be87d3b460d677d',
        'shortname'    => undef,
        'default_contact_method_uuid' =>
          'acf522ee6a4fcb28746fad2774a5b7d9b905ef75'
    },
    {
        '_'             => 'new_work',
        'start'         => '1438693448000',
        'bill'          => 1,
        'stop'          => '1438693456000',
        'node_uuid'     => 'f1b417064a8a4e0ee92cb6270be87d3b460d677d',
        'identity_uuid' => 'f1b417064a8a4e0ee92cb6270be87d3b460d677d',
        'offset'        => 7200000
    },
    {
        '_'         => 'command',
        'type'      => 'id',
        'node_uuid' => 'f1b417064a8a4e0ee92cb6270be87d3b460d677d',
        'format'    => 'new identity %s Mark Lawrence (ML)'
    },
    {
        '_'             => 'end_change',
        'uuid'          => 'fb1a94b4c01e67d9df958374da59dfb510e588e8',
        'message'       => '|new identity',
        'identity_uuid' => 'f1b417064a8a4e0ee92cb6270be87d3b460d677d'
    }
];

my $bifcode1;
my $bifcode1_perl;
my $bifcode;
my $bifcode_perl;
my $bencode;
my $bencode_perl;
my $json_pp;
my $json_pp_perl;
my $json_tiny;
my $json_tiny_perl;
my $yaml_tiny;
my $yaml_tiny_perl;
my $sereal;
my $sereal_perl;

use Sereal;
my $serenc = Sereal::Encoder->new(
    {
        no_shared_hashkeys => 1,
        dedupe_strings     => 1,
        compress           => Sereal::Encoder::SRL_ZLIB
    }
);
my $serdec = Sereal::Decoder->new;

print "Encoding\n";
cmpthese(
    $rounds,
    {
        'Bifcode' => sub { $bifcode1 = Bifcode::encode_bifcode($data) },
        'Bifcode' => sub { $bifcode  = Bifcode::encode_bifcode($data) },

     #        'Bencode'    => sub { $bencode   = Bencode::bencode($data) },
     #        'JSON:PP'    => sub { $json_pp   = JSON::PP::encode_json($data) },
        'JSON::Tiny' => sub { $json_tiny = JSON::Tiny::encode_json($data) },
        'YAML::XS'   => sub { $yaml_tiny = YAML::XS::Dump($data) },
        'Sereal'     => sub { $sereal    = $serenc->encode($data) },
    }
);

print "\n";
print "Decoding\n";
cmpthese(
    $rounds,
    {
        'Bifcode' =>
          sub { $bifcode1_perl = Bifcode::decode_bifcode($bifcode1) },
        'Bifcode' => sub { $bifcode_perl = Bifcode::decode_bifcode($bifcode) },

  #        'Bencode' => sub { $bencode_perl = Bencode::bdecode($bencode) },
  #        'JSON:PP' => sub { $json_pp_perl = JSON::PP::decode_json($json_pp) },
        'JSON::Tiny' =>
          sub { $json_tiny_perl = JSON::Tiny::decode_json($json_tiny) },
        'YAML::XS' => sub { $yaml_tiny_perl = YAML::XS::Load($yaml_tiny) },
        'Sereal'   => sub { $sereal_perl    = $serdec->decode($sereal) },
    }
);

my @list = (
    [ 'bifcodeV1:       ', $bifcode1, $bifcode1_perl ],
    [ 'bifcode:       ',   $bifcode,  $bifcode_perl ],

    #    [ 'bencode:   ',     $bencode,   $bencode_perl ],
    #    [ 'json_pp:   ',     $json_pp,   $json_pp_perl ],
    [ 'json_tiny: ', $json_tiny, $json_tiny_perl ],
    [ 'sereal ',     $sereal,    $sereal_perl ],
    [ 'yaml_tiny: ', $yaml_tiny, $yaml_tiny_perl ]
);

print "\n";
print "Output\n";
foreach my $e (@list) {
    if ( $size < 2 ) {
        printf "%8s: %s\n", $e->[0],
          $e->[1] . ( utf8::is_utf8( $e->[1] ) ? ' (utf8)' : '' );
    }
    my $x = $e->[1];
    utf8::encode($x);
    $e->[3] = Compress::Zlib::memGzip($x);
}

print "\n";
print "Sizes\n";
foreach my $e (@list) {
    printf "%8s: %s, gzip: %s (%.2f%%)\n", $e->[0], bytes::length( $e->[1], ),
      bytes::length( $e->[3] ),
      bytes::length( $e->[3] ) * 100.0 / bytes::length( $e->[1] );
}

local $Data::Dumper::Indent    = 1;
local $Data::Dumper::Purity    = 0;
local $Data::Dumper::Terse     = 1;
local $Data::Dumper::Deepcopy  = 1;
local $Data::Dumper::Quotekeys = 0;
local $Data::Dumper::Useperl   = 1;
local $Data::Dumper::Sortkeys  = 1;

print "\n";
print "Round-trip\n";
foreach my $e (@list) {
    printf "%8s: %s\n", $e->[0],
      diff( \Dumper( $e->[2]->[0] ), \Dumper( $data->[0] ) );
}

#warn $yaml_tiny;

__END__
89504e470d0a1a0a0000000d49484452000000d8000000d80103000000b3
eebfae00000006504c5445000000ffffffa5d99fdd000000ae4944415478
5eddd5410a80301403d1dcffd2153304bbf10213a4fce6fd8d2098f31f87
85bc13bb6b2cc67b525f8dc74203add1599f17ad462b34daf587c66384f9
6a2c76857e1789a51e0e6ea17758bba020a7c33810869d16dbb5d6797787
05df5a193118c59082bbc532caba89c30e6d4a7de023b1ec3de1645b1223
4cfb70d9765848cb64ddf1d8f70d23bb692cd7ef7f414cd630a22aaba6cc
9068accdca34740e23a70f2bac4aec370a7b0057273b7cbba8fcf7000000
0049454e44ae426082
