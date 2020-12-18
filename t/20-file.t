use warnings;
use strict;

use Test::More;

use Word::Rhymes;

my $mod = 'Word::Rhymes';

#
# file
#

# new param default
{
    my $o = $mod->new;
    is $o->file, '', "default file is blank ok";
}

# file does not exist
{
    is
        eval {$mod->new(file => 'blah.blah'); 1},
        undef,
        "file does not exist croaks ok";

    like $@, qr/does not exist/, "...and error is sane";
}

# file isn't a file
{
    is
        eval {$mod->new(file => 'lib/'); 1},
        undef,
        "file isn't a file fails ok";

    like $@, qr/valid file/, "...and error is sane";
}

# method
{
    my $o = $mod->new;

    is
        eval {$o->file('blah.blah'); 1},
        undef,
        "method file() does not exist croaks ok";

    like $@, qr/does not exist/, "...and error is sane";

    is
        eval {$o->file('/lib'); 1},
        undef,
        "file() croaks if the file isn't a real file ok";

    like $@, qr/valid file/, "...and error is sane";
}

done_testing;