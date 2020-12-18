use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Word::Rhymes;

use constant {
    SORT_BY_SCORE_DESC  => 0x00, # Default
    SORT_BY_SCORE_ASC   => 0x01,
    SORT_BY_ALPHA_DESC  => 0x02,
    SORT_BY_ALPHA_ASC   => 0x03,
};

my $mod = 'Word::Rhymes';
my $f = 't/data/zoo.data';
my $w = 'zoo';

#
# sort_by
#

# param
{
    # score_desc (default)
    {
        my $d = $mod->new(file => $f)->fetch($w)->{1};
        is $d->[0]{score}, 18213, "param: first sorted in score desc ok";
        is $d->[-1]{score}, 1, "param: last sorted in score desc ok";
    }

    # score_asc
    {
        my $d = $mod->new(file => $f, sort_by => 'score_asc')->fetch($w)->{1};
        is $d->[0]{score}, 1, "param: score_asc ok";
        is $d->[-1]{score}, 18213, "param: score asc ok";
    }

    # alpha_desc
    {
        my $d = $mod->new(file => $f, sort_by => 'alpha_desc')->fetch($w)->{1};
        is $d->[0]{word}, 'zooplasty', "param: first sorted in alpha_desc ok";
        is $d->[-1]{word}, 'beu', "param: last sorted in alpha_desc ok";
    }

    # score_asc
    {
        my $d = $mod->new(file => $f, sort_by => 'alpha_asc')->fetch($w)->{1};
        is $d->[0]{word}, 'beu', "param: score_asc ok";
        is $d->[-1]{word}, 'zooplasty', "param: score asc ok";
    }
}

# method
{
    my $o = $mod->new(file => $f);
    my $d;

    $o->sort_by('score_asc');
    $d = $o->fetch('zoo')->{1};
    is $d->[0]{score}, 1, "method: score_asc ok";
    is $d->[-1]{score}, 18213, "method: score asc ok";

    $o->sort_by('alpha_desc');
    $d = $o->fetch('zoo')->{1};
    is $d->[0]{word}, 'zooplasty', "method: first sorted in alpha_desc ok";
    is $d->[-1]{word}, 'beu', "method: last sorted in alpha_desc ok";

    $o->sort_by('alpha_asc');
    $d = $o->fetch('zoo')->{1};
    is $d->[0]{word}, 'beu', "method: first sorted in alpha_asc ok";
    is $d->[-1]{word}, 'zooplasty', "method: last sorted in alpha_asc ok";
}

done_testing;
