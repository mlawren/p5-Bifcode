use strict;
use warnings;
use lib 'lib';
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use Test::Bifcode;
use Test::More 0.88;    # for done_testing
use Test::Needs 'Text::Diff';
use Bifcode 'encode_bifcode', 'diff_bifcode';

eval { diff_bifcode() };
like $@, qr/usage: diff_bifcode\(\$b1, \$b2\)/, 'not enough arguments';

eval { encode_bifcode( 1, 2, 3 ) };
like $@, qr/usage: encode_bifcode\(\$arg\)/, 'too many arguments';

my $a = '[U1:aU1:bU1:c]';
my $b = '[U1:aU1:B~]';

is diff_bifcode( $a, $a ), '', 'same bifcode no diff';

like diff_bifcode( $a, $b ), qr/- .*\+ /sm, 'diff bifcode structure';

$a = '[U1:aX1:bU1:c]';
$b = '[U1:aU1:B~]';

like diff_bifcode( $a, $b ), qr/-[0-9]+:.*\+[0-9]+:/sm, 'diff bifcode expanded';

done_testing;
