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
like $@, qr/usage: diff_bifcode/, 'diff_bifcode not enough arguments';

eval { diff_bifcode( 1, 2, 3, 4 ) };
like $@, qr/usage: diff_bifcode/, 'diff_bifcode too many arguments';

eval { encode_bifcode( 1, 2, 3 ) };
like $@, qr/usage: encode_bifcode\(\$arg\)/, 'too many arguments';

my $a = '[U1:aU1:bU1:c]';
my $b = '[U1:aU1:B~]';

is diff_bifcode( $a, $a ), '', 'same bifcode no diff';

like diff_bifcode( $a, $b ), qr/^ \[$/sm,   'bifcode expanded';
like diff_bifcode( $a, $b ), qr/^(-|\+)/sm, 'diff text structure';

$a = '[U1:aX1:bU1:c]';
$b = '[U1:aU1:B~]';

like diff_bifcode( $a, $b ), qr/^ \[$/sm,   'bifcode expanded on invalid';
like diff_bifcode( $a, $b ), qr/^(-|\+)/sm, 'diff text structure on invalid';

done_testing;
