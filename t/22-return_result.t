use warnings;
use strict;

use JSON;
use Test::More;
use Word::Rhymes;

my $mod = 'Word::Rhymes';

my $j = JSON->new;

# return_json
{
    my $o = $mod->new;
    print $j->pretty->encode( $o->fetch('zoo'));
}

done_testing;
