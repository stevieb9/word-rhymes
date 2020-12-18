use warnings;
use strict;

use Test::More;

use Word::Rhymes;

my $mod = 'Word::Rhymes';

# word: master
{
    my $o = $mod->new;
    $o->fetch('master');
}

done_testing;
