use strict;
use warnings;
use Test::More;

use macro
    FOO => 'my $foo = 42';

FOO;

is($foo, 42);

done_testing();
