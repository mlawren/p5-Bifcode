use strict;
use warnings;
use Test::More 0.88;    # for done_testing
use BBE;

ok $BBE::TRUE, 'Perl think BBE::TRUE is true';
eval { $BBE::TRUE++ };
like $@, qr/immutable/, 'Cannot increment Boolean';
is $BBE::TRUE + 1, 2, 'TRUE + 1';
is $BBE::TRUE, 1, 'TRUE is still 1';

ok !$BBE::FALSE, 'Perl thinks BBE::FALSE is false';
eval { $BBE::FALSE-- };
like $@, qr/immutable/, 'Cannot decrement Boolean';
is $BBE::FALSE + 1, 1, 'FALSE + 1';
is $BBE::FALSE, 0, 'FALSE is still 0';

done_testing();
