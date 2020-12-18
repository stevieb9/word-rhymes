use warnings;
use strict;

use Test::More;

use Word::Rhymes;

my $mod = 'Word::Rhymes';

#
# min_score
#

# new param default
{
    my $o = $mod->new;
    is $o->min_score, 0, "default min_score ok";
}

# new param wrong type
{
    is
        eval {$mod->new(min_score => 'aaa'); 1},
        undef,
        'min_score param croaks if not int ok';

    like $@, qr/min_score must be an integer/, "...and error is sane";
}

# new param too high
{
    is
        eval {$mod->new(min_score => 1000001); 1},
        undef,
        'min_score param croaks if over 1,000,000 ok';

    like $@, qr/min_score must be between/, "...and error is sane";
}

# new param too low
{
    is
        eval {$mod->new(min_score => -1); 1},
        undef,
        'min_score param croaks if under 0 ok';

    like $@, qr/min_score must be between/, "...and error is sane";
}

# method
{
    my $o = $mod->new;

    is
        eval {$o->min_score('aaa'); 1},
        undef,
        "min_score() croaks on non int ok";

    like $@, qr/min_score must be an integer/, "...and error is sane";

    is
        eval {$o->min_score(-1); 1},
        undef,
        "min_score() croaks if param < 0 ok";

    like $@, qr/must be between/, "...and error is sane";

    is
        eval {$o->min_score(1000001); 1},
        undef,
        "min_score() croaks if param > 1,000,000 ok";

    like $@, qr/must be between/, "...and error is sane";

    done_testing; exit;

    for (1..1,000,000) {
        is $o->min_score($_), $_, "min_score with $_ ok";
    }
}

done_testing;