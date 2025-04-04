use strict;
use warnings;
use lib 't/lib';
use Bifcode::V1 'encode_bifcode', 'diff_bifcode';
use Test::Bifcode::V1;
use Test2::V0;
use Test2::Require::Module 'Text::Diff';

eval { diff_bifcode() };
isa_ok $@, ['Bifcode::Error::DiffUsage'], 'diff_bifcode not enough arguments';

eval { diff_bifcode( 1, 2, 3, 4 ) };
isa_ok $@, ['Bifcode::Error::DiffUsage'], 'diff_bifcode too many arguments';

eval { encode_bifcode( 1, 2, 3 ) };
isa_ok $@, ['Bifcode::Error::EncodeUsage'], 'too many arguments';

my $a = '[U1:a,U1:b,U1:c,]';
my $b = '[U1:a,U1:B,~]';

is diff_bifcode( $a, $a ), '', 'same bifcode no diff';

like diff_bifcode( $a, $b ), qr/^ \[$/sm,   'bifcode expanded';
like diff_bifcode( $a, $b ), qr/^(-|\+)/sm, 'diff text structure';

$a = '[U1:a,X1:b,U1:c,]';
$b = '[U1:a,U1:B,~]';

like diff_bifcode( $a, $b ), qr/^ \[$/sm,   'bifcode expanded on invalid';
like diff_bifcode( $a, $b ), qr/^(-|\+)/sm, 'diff text structure on invalid';

done_testing;
