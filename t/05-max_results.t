use warnings;
use strict;

use Test::More;

use Word::Rhymes;

my $mod = 'Word::Rhymes';

#
# max_results
#

# new param default
{
    my $o = $mod->new;
    is $o->max_results, 1000, "default max_results ok";
}

# new param wrong type
{
    is
        eval {$mod->new(max_results => 'aaa'); 1},
        undef,
        'max_results param croaks if not int ok';

    like $@, qr/max_results must be an integer/, "...and error is sane";
}

# new param too high
{
    is
        eval {$mod->new(max_results => 1001); 1},
        undef,
        'max_results param croaks if over 1000 ok';

    like $@, qr/max_results must be between/, "...and error is sane";
}

# new param too low
{
    is
        eval {$mod->new(max_results => 0); 1},
        undef,
        'max_results param croaks if under 1 ok';

    like $@, qr/max_results must be between/, "...and error is sane";
}

# method
{
    my $o = $mod->new;

    is
        eval {$o->max_results('aaa'); 1},
        undef,
        "max_results() croaks on non int ok";

    like $@, qr/max_results must be an integer/, "...and error is sane";

    is
        eval {$o->max_results(0); 1},
        undef,
        "max_results() croaks if param < 1 ok";

    like $@, qr/must be between/, "...and error is sane";

    is
        eval {$o->max_results(1001); 1},
        undef,
        "max_results() croaks if param > 1000 ok";

    like $@, qr/must be between/, "...and error is sane";
done_testing; exit;
    for (1..1000) {
        is $o->max_results($_), $_, "max_results with $_ ok";
    }
}

done_testing;