use strict;
use warnings;
use lib 'lib';
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use Test2::V0;
use Test2::Require::Module 'Text::Diff';
use Test::Bifcode;
use Bifcode::V2 'encode_bifcodeV2', 'diff_bifcodeV2';

eval { diff_bifcodeV2() };
isa_ok $@, ['Bifcode::Error::DiffUsage'], 'diff_bifcodeV2 not enough arguments';

eval { diff_bifcodeV2( 1, 2, 3, 4 ) };
isa_ok $@, ['Bifcode::Error::DiffUsage'], 'diff_bifcodeV2 too many arguments';

eval { encode_bifcodeV2( 1, 2, 3 ) };
isa_ok $@, ['Bifcode::Error::EncodeUsage'], 'too many arguments';

my $a = '[u1.a,u1.b,u1.c,]';
my $b = '[u1.a,u1.B,~,]';

is diff_bifcodeV2( $a, $a ), '', 'same bifcode no diff';

like diff_bifcodeV2( $a, $b ), qr/^ \[$/sm,   'bifcode expanded';
like diff_bifcodeV2( $a, $b ), qr/^(-|\+)/sm, 'diff text structure';

$a = '[u1.a,x1:b,u1.c,]';
$b = '[u1.a,u1.b,~,]';

like diff_bifcodeV2( $a, $b ), qr/^ \[$/sm,   'bifcode expanded on invalid';
like diff_bifcodeV2( $a, $b ), qr/^(-|\+)/sm, 'diff text structure on invalid';

done_testing;
