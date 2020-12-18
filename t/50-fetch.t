use warnings;
use strict;

use Test::More;

use Word::Rhymes;

my $mod = 'Word::Rhymes';
my $f = 't/data/zoo.data';

ok 1;
# word: zoo
{
    my $o = $mod->new(file => $f);

    $o->fetch('master');
}

done_testing;
