use strict;
use warnings;
use lib 'lib';
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use Test::Bifcode2;
use Test2::V0;
use Test2::Require::Module 'Text::Diff';
use Bifcode2 'encode_bifcode2', 'diff_bifcode2';

eval { diff_bifcode2() };
isa_ok $@, ['Bifcode2::Error::DiffUsage'], 'diff_bifcode2 not enough arguments';

eval { diff_bifcode2( 1, 2, 3, 4 ) };
isa_ok $@, ['Bifcode2::Error::DiffUsage'], 'diff_bifcode2 too many arguments';

eval { encode_bifcode2( 1, 2, 3 ) };
isa_ok $@, ['Bifcode2::Error::EncodeUsage'], 'too many arguments';

my $a = '[u1.a,u1.b,u1.c,]';
my $b = '[u1.a,u1.B,~,]';

is diff_bifcode2( $a, $a ), '', 'same bifcode no diff';

like diff_bifcode2( $a, $b ), qr/^ \[$/sm,   'bifcode expanded';
like diff_bifcode2( $a, $b ), qr/^(-|\+)/sm, 'diff text structure';

$a = '[u1.a,x1:b,u1.c,]';
$b = '[u1.a,u1.b,~,]';

like diff_bifcode2( $a, $b ), qr/^ \[$/sm,   'bifcode expanded on invalid';
like diff_bifcode2( $a, $b ), qr/^(-|\+)/sm, 'diff text structure on invalid';

done_testing;
