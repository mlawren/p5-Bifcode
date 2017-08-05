use strict;
use warnings;
use Test::More 0.88;    # for done_testing
use Bifcode;

ok $Bifcode::TRUE, 'Perl think Bifcode::TRUE is true';
eval { $Bifcode::TRUE++ };
like $@, qr/immutable/, 'Cannot increment Boolean';
is $Bifcode::TRUE + 1, 2, 'TRUE + 1';
is $Bifcode::TRUE, 1, 'TRUE is still 1';

ok !$Bifcode::FALSE, 'Perl thinks Bifcode::FALSE is false';
eval { $Bifcode::FALSE-- };
like $@, qr/immutable/, 'Cannot decrement Boolean';
is $Bifcode::FALSE + 1, 1, 'FALSE + 1';
is $Bifcode::FALSE, 0, 'FALSE is still 0';

done_testing();
