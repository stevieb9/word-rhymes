package Word::Rhymes;

use strict;
use warnings;

our $VERSION = '1.01';

use Carp qw(croak);
use HTTP::Request;
use JSON;
use LWP::UserAgent;

use constant {
    # Core
    MIN_SCORE           => 0,
    MAX_SCORE           => 1000000,
    MIN_RESULTS         => 1,
    MAX_RESULTS         => 1000,
    MIN_SYLLABLES       => 1,
    MAX_SYLLABLES       => 100,
    MULTI_WORD          => 0,
    RETURN_RAW          => 0,

    # print() related
    MAX_NUM_COLS        => 8,
    MIN_NUM_COLS        => 7,
    COL_DIVIDER         => 15,
    COL_PADDING         => 3,
    ROW_INDENT          => '    ',

    # Sort by
    SORT_BY_SCORE_DESC  => 0x00, # Default
    SORT_BY_SCORE_ASC   => 0x01,
    SORT_BY_ALPHA_DESC  => 0x02,
    SORT_BY_ALPHA_ASC   => 0x03,

};

my $ua = LWP::UserAgent->new;

# Public

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->_args(\%args);

    return $self;
}
sub fetch {
    my ($self, $word, $context) = @_;

    if (! defined $word) {
        croak("fetch() needs a word sent in");
    }

    if (defined $context && $context !~ /^\w+$/) {
        croak("context parameter must be an alpha word only.");
    }

    my ($req, $response);

    if (! $self->file) {
        $req = HTTP::Request->new('GET', $self->_uri($word, $context));
        $response = $ua->request($req);
    }

    if ($self->file || $response->is_success) {

        my $json;

        if ($self->file) {
            {
                local $/;
                open my $fh, '<', $self->file or croak(
                    sprintf("Can't open the data file '%s': $!", $self->file)
                );
                $json = <$fh>;
                close $fh;
            }
        }
        else {
            $json = $response->decoded_content;
        }

        my $result = decode_json $json;

        return $result if $self->return_raw;

        return $self->_process($result);
    }
    else {
        print "Invalid response\n\n";
        return undef;
    }
}
sub file {
    my ($self, $file) = @_;

    if (defined $file) {
        croak("File '$file' does not exist") if ! -e $file;
        croak("File '$file' is not a valid file") if ! -f $file;
        $self->{file} = $file;
    }

    return $self->{file} // '';
}
sub max_results {
    my ($self, $max) = @_;

    if (defined $max) {
        croak("max_results must be an integer") if $max !~ /^\d+$/;
        if ($max < MIN_RESULTS || $max > MAX_RESULTS) {
            croak(
                sprintf(
                    "max_results must be between %d and %d",
                    MIN_RESULTS,
                    MAX_RESULTS
                )
            );
        }
        $self->{max_results} = $max;
    }

    return $self->{max_results} // MAX_RESULTS;
}
sub min_score {
    my ($self, $min) = @_;

    if (defined $min) {
        croak("min_score must be an integer") if $min !~ /^-?\d+$/;
        if ($min < MIN_SCORE || $min > MAX_SCORE) {
            croak(
                sprintf(
                    "min_score must be between %d and %d",
                    MIN_SCORE,
                    MAX_SCORE
                )
            );
        }
        $self->{min_score} = $min;
    }

    return $self->{min_score} // MIN_SCORE;
}
sub min_syllables {
    my ($self, $min) = @_;

    if (defined $min) {
        croak("min_syllables must be an integer") if $min !~ /^-?\d+$/;
        if ($min < MIN_SYLLABLES || $min > MAX_SYLLABLES) {
            croak(
                sprintf(
                    "min_syllables must be between %d and %d",
                    MIN_SYLLABLES,
                    MAX_SYLLABLES
                )
            );
        }
        $self->{min_syllables} = $min;
    }

    return $self->{min_syllables} // MIN_SYLLABLES;
}
sub multi_word {
    my ($self, $bool) = @_;

    if (defined $bool) {
        $self->{multi_word} = $bool;
    }

    return $self->{multi_word} // MULTI_WORD;
}
sub print {
    my ($self, $word, $context) = @_;

    my $rhyming_words = $self->fetch($word, $context);

    print defined $context
        ? "\nRhymes with '$word' related to '$context'\n"
        : "\nRhymes with '$word'\n";

    for my $num_syl (reverse sort keys %$rhyming_words) {
        my $max_word_len = length(
            (sort {length $b->{word} <=> length $a->{word}} @{ $rhyming_words->{$num_syl} })[0]->{word}
        );

        my $column_width = $max_word_len + COL_PADDING;
        my $columns = $column_width > COL_DIVIDER ? MIN_NUM_COLS : MAX_NUM_COLS;

        printf "\nSyllables: $num_syl\n\n%s", ROW_INDENT;

        for (0 .. $#{ $rhyming_words->{$num_syl} }) {
            printf "\n%s", ROW_INDENT if $_ % $columns == 0 && $_ != 0;
            printf("%-*s", $column_width, $rhyming_words->{$num_syl}[$_]->{word});
        }
        print "\n";
    }

    return 0;
}
sub return_raw {
    my ($self, $ret) = @_;

    if (defined $ret) {
        $self->{return_raw} = $ret;
    }

    return $self->{return_raw} // RETURN_RAW;
}
sub sort_by {
    my ($self, $sort_by) = @_;

    if (defined $sort_by) {
        if (! grep /^$sort_by$/, qw(score_desc score_asc alpha_desc alpha_asc)) {
            croak("sort() needs 'score_desc', 'score_asc', 'alpha_desc' or 'alpha_asc' as param");
        }

        if ($sort_by =~ /^alpha/) {
            $self->{sort_by} =  $sort_by =~ /desc/
                ? SORT_BY_ALPHA_DESC
                : SORT_BY_ALPHA_ASC;
        }
        elsif ($sort_by =~ /^score/) {
            $self->{sort_by} = $sort_by =~ /desc/
                ? SORT_BY_SCORE_DESC
                : SORT_BY_SCORE_ASC;
        }
    }

    return $self->{sort_by} // SORT_BY_SCORE_DESC;
}

# Private

sub _args {
    my ($self, $args) = @_;

    # file
    $self->file($args->{file}) if exists $args->{file};

    # max_results
    $self->max_results($args->{max_results}) if exists $args->{max_results};

    # min_score
    $self->min_score($args->{min_score}) if exists $args->{min_score};

    # min_syllables
    $self->min_syllables($args->{min_syllables}) if exists $args->{min_syllables};

    # multi_word
    $self->multi_word($args->{multi_word}) if exists $args->{multi_word};

    # return_raw
    $self->return_raw($args->{return_raw}) if exists $args->{return_raw};

    # sort_by
    $self->sort_by($args->{sort_by}) if exists $args->{sort_by};
}
sub _process {
    my ($self, $result) = @_;

    my @data;

    # Dump rhyming words that don't have a score or are multi-word
    if ($self->multi_word) {
        @data = grep { $_->{score} } @$result;
    }
    else {
        @data = grep { $_->{score} && $_->{word} !~ /\s+/ } @$result;
    }

    # Dump rhyming words that are outside of min_syllables threshold
    @data = grep { $_->{numSyllables} >= $self->min_syllables } @data;

    my @sorted = sort {$b->{numSyllables} <=> $a->{numSyllables}} @data;
    my %organized;

    for (@sorted) {
        push @{ $organized{$_->{numSyllables}} }, $_ if $_->{score} >= $self->min_score;
    }

    for (keys %organized) {
        if ($self->sort_by == SORT_BY_ALPHA_DESC) {
            @{ $organized{$_} } = sort {$b->{word} cmp $a->{word}} @{ $organized{$_} };
        }
        elsif ($self->sort_by == SORT_BY_ALPHA_ASC) {
            @{ $organized{$_} } = sort {$a->{word} cmp $b->{word}} @{ $organized{$_} };
        }
        elsif ($self->sort_by == SORT_BY_SCORE_DESC) {
            @{ $organized{$_} } = sort {$b->{score} <=> $a->{score}} @{ $organized{$_} };
        }
        elsif ($self->sort_by == SORT_BY_SCORE_ASC) {
            @{ $organized{$_} } = sort {$a->{score} <=> $b->{score}} @{ $organized{$_} };
        }
    }
    return \%organized;

}
sub _uri {
    my ($self, $word, $context) = @_;

    my $uri;

    if (defined $context) {
        $uri = sprintf(
            "http://api.datamuse.com/words?max=%d&ml=%s&rel_rhy=%s",
            $self->max_results,
            $context,
            $word
        );
    }
    else {
        $uri = sprintf(
            "http://api.datamuse.com/words?max=%d&rel_rhy=%s",
            $self->max_results,
            $word
        );
    }

    return $uri;
}
sub __placeholder {}

1;
__END__

=head1 NAME

Word::Rhymes - Takes a word and fetches rhyming matches from RhymeZone.com

=for html
<a href="http://travis-ci.com/stevieb9/word-rhymes"><img src="https://www.travis-ci.com/stevieb9/word-rhymes.svg?branch=master"/>
<a href='https://coveralls.io/github/stevieb9/word-rhymes?branch=master'><img src='https://coveralls.io/repos/stevieb9/word-rhymes/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 DESCRIPTION

This distribution has installed a pre-written binary application for ease of
use. Please see the
L<rhyme|https://metacpan.org/pod/distribution/Word-Rhymes/bin/rhyme>
documentation for full details.

Provides the ability to fetch words that rhyme with a word, while allowing for
context if desired (eg. find all words that rhyme with baseball that relate
to breakfast).

Ability to change sort order, minimum rhyme match score, maximum number of
words returned etc.

=head1 SYNOPSIS

    use Word::Rhymes;

    my $wr = Word::Rhymes->new;

    # Simply display the output

    $wr->print('disdain');

    # Print all matching rhyming words that have three syllables

    my $rhyming_words = $wr->fetch('disdain');
    print "$_\n" for @{ $rhyming_words->{3} };

    # With context (rhymes with 'disdain', but only words relating to 'farm')

    $rhyming_words = $wr->fetch('disdain', 'farm');

=head1 METHODS

=head2 new

Instantiates and returns a new L<< Word::Rhymes >> object.

B<Parameters>

All parameters are passed in within a hash, and are every one of them optional.

The parameters have an associated setter/getter method, so to see details for
each parameter, follow through to the relevant method documentation.

    file => $filename

Used mainly for testing. Allows you to re-use existing, saved data. See
L</file>.

    max_results => $integer

Sets the maximum number of rhyming words that'll be fetched over the Internet.
See L</max_results>.

    min_score => $integer

We ignore rhyming words with a score less than what you set here. See
L</min_score>.

    min_syllables => $integer

Ignore rhyming words with less than the set number of syllables. See
L</min_syllables>.

    multi_word => $bool

By default, we ignore rhyming "words" that have more than one word (ie. a
phrase). You can use this parameter to include them. See L</multi_word>.

    return_raw => $bool

Set to true to get returned via L</fetch> the data prior to all filtering and
manipulation taking place. Used primarily for development and testing.
See L</return_raw>.

    sort_by => $string

Sort by C<score_desc> (default), C<score_asc>, C<alpha_asc> or C<alpha_desc>.
See L</sort_by>.

B<Returns>: L<Word::Rhymes> object.

=head2 fetch

Performs the fetching of the rhyming words.

B<Parameters>

    $word

B<Mandatory, String>: The word that'll be used to find rhyming matches to.

    $context

B<Optional, String>: This word is used to surround the rhyming words with
context. For example, if C<$word> is C<animal> and C<$context> is C<zoo>, we'll
fetch words that rhyme with animal but that are only related to a zoo somehow.

B<Returns>: A hash reference where the keys are the number of syllables in the
rhyming words, and the values are array reference with the ordered data
structure containing the word, the number of syllables and the score.

=head2 print

This method will display to the screen instead of returning results which is
what L</fetch> is used for.

B<Parameters>

    $word

B<Mandatory, String>: The word that'll be used to find rhyming matches to.

    $context

B<Optional, String>: This word is used to surround the rhyming words with
context. For example, if C<$word> is C<animal> and C<$context> is C<zoo>, we'll
fetch words that rhyme with animal but that are only related to a zoo somehow.

B<Returns>: 0 upon success.

=head2 file

Used primarily for development and testing, allows you to skip fetching results
from the Internet, and instead fetches the data from a pre-saved file.

B<Parameters>

    $file

B<Optional, String>: The name of a pre-existing file.

B<Default>: Empty string.

B<Returns>: The name of the file if set, empty string otherwise.

=head2 max_results

Sets the maximum number of rhyming words to fetch over the Internet.

B<Parameters>

    $max

B<Optional, Integer>: An integer in the range of 1-1000.

B<Default>: 1000

B<Returns>: Integer, the currently set value.

=head2 min_score

We will only return rhyming words with a score higher than the number set here.

B<Parameters>

    $min

B<Optional, Integer>: An integer in the range of 0-1000000.

B<Default>: 0

B<Returns>: Integer, the currently set value.

=head2 min_syllables

We will only return rhyming words with a syllable count equal to or higher than
the number set here.

B<Parameters>

    $min

B<Optional, Integer>: An integer in the range of 1-100 (yeah, I haven't heard
of a word with 100 syllables either, but I digress).

B<Default>: 1

B<Returns>: Integer, the currently set value.

=head2 multi_word

Some rhyming words are actually multi-word phrases. By default, we skip over
these. Set this to a true value to have the multi worded rhyming words included
in the results.

B<Parameters>

    $bool

B<Optional, Bool>: Set to true to include multi-words, and false to skip over
them.

B<Default>: 0 (false)

B<Returns>: Bool, the currently set value.

=head2 return_raw

Used primarily for development and testing. Set to true to have L</fetch>
return the results as they were received, prior to any other processing.

B<Parameters>

    $bool

B<Optional, Bool>: Set to true to have the results returned before any
processing occurs.

B<Default>: 0 (false)

B<Returns>: Bool, the currently set value.

=head2 sort_by

This method allows you to modify the sorting of the rhyming words prior to
them being returned.

B<Parameters>

    $sort_order

B<Optional, String>: The values for the parameter are as such:

    score_desc

The rhyming words will be sorted according to score, in a descending order
(ie. highest to lowest). This is the default.

    score_asc

Return the rhyming words in ascending score order (ie. lowest to highest).

    alpha_desc

Return the rhyming words in alphabetical descending order (ie. a-z).

    alpha_asc

Return the rhyming words in alphabetical ascending order (ie. z-a).

B<Default>: C<score_desc> (0x00).

B<Returns>: Integer, the currently set value:

    score_desc:     0x00
    score_asc:      0x01
    ascii_desc:     0x02
    ascii_asc:      0x03

B<Returns>: Bool, the currently set value.

=head1 PRIVATE METHODS

=head2 _args

Handles the processing of parameters sent into L</new>. See that documentation
for details on the various valid parameters.

=head2 _process

Called by L</fetch>, processes the data retrieved from RhymeZone.com.

=head2 _uri

Generates and returns the appropriate URL for the RhymeZone.com REST API.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
