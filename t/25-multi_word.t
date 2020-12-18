use warnings;
use strict;

use Test::More;
use Word::Rhymes;

my $mod = 'Word::Rhymes';

#
# multi_word
#

# new param default
{
    my $o = $mod->new;
    is $o->multi_word, 0, "default multi_word ok";
}

# new param set
{
    my $o = $mod->new(multi_word => 1);
    is $o->multi_word, 1, 'multi_word param set ok';
}

# method
{
    my $o = $mod->new;

    is
        $o->multi_word(1),
        1,
        "multi_word() set ok";
}

# counts
{
    # no multi_word (default)
    {
        my $o = $mod->new;

        my $c;

        my $data = $o->fetch('zoo');

        for my $syl (keys %$data) {
            $c += scalar @{ $data->{$syl} };
        }

        print "count: $c\n";
    }
}

done_testing;