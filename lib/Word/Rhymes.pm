package Word::Rhymes;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak);
use Data::Dumper;
use JSON;
use HTTP::Request;
use LWP::UserAgent;

my $DEBUG = $ENV{WORD_RHYMES_DEBUG};

use constant {
    # Core limits
    MIN_SCORE           => 0,
    MAX_SCORE           => 1000000,
    MIN_RESULTS         => 1,
    MAX_RESULTS         => 1000,
    MIN_SYLLABLES       => 1,
    MAX_SYLLABLES       => 100,

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
    my ($self, $word, $context, $raw) = @_;

    print "Word: $word, Context: $context\n" if $DEBUG && defined $context;
    print "Word: $word\n" if $DEBUG && ! defined $context;

    if (! defined $word) {
        croak("fetch() needs a word sent in");
    }
    if (defined $context && $context !~ /[a..zA..Z-]/) {
        croak("context parameter must be an alpha word only.");
    }

    my $req = HTTP::Request->new('GET', $self->_uri($word, $context));

    my $response = $ua->request($req);

    if ($response->is_success) {
        my $result = decode_json $response->decoded_content;

        # Dump rhyming words that don't have a score
        my @data = grep { $_->{score} } @$result;

        my @sorted = sort {$b->{numSyllables} <=> $a->{numSyllables}} @data;
        my %organized;

        printf "Min score: %d\n", $self->min_score if $DEBUG;

        for (@sorted) {
            push @{ $organized{$_->{numSyllables}} }, $_ if $_->{score} >= $self->min_score;
        }

        if (defined $raw) {
            return \%organized;
        }

        printf("SORT BY: %s\n", $self->sort_by) if $DEBUG;

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
    else {
        print "Invalid response\n\n";
        return undef;
    }
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

        if ($DEBUG) {
            printf "$num_syl syllables: matched word count: %d\n", scalar keys %$rhyming_words;
            printf "column width: %d, column count: %d\n", $column_width, $columns;
        }

        printf "\nSyllables: $num_syl\n\n%s", ROW_INDENT;

        for (0 .. $#{ $rhyming_words->{$num_syl} }) {
            printf "\n%s", ROW_INDENT if $_ % $columns == 0 && $_ != 0;
            printf("%-*s", $column_width, $rhyming_words->{$num_syl}[$_]->{word});
        }
        print "\n";
    }
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

    # max_results
    if (exists $args->{max_results}) {
        $self->max_results($args->{max_results});
    }

    # min score
    if (exists $args->{min_score}) {
        $self->min_score($args->{min_score});
    }

    # min syllables
    if (exists $args->{min_syllables}) {
        $self->min_syllables($args->{min_syllables});
    }

    # sort by
    if (exists $args->{sort_by}) {
        $self->sort_by($args->{sort_by});
    }
}
sub _uri {
    my ($self, $word, $context) = @_;

    my $uri;

    if (defined $context) {
        $uri = sprintf(
            "http://api.datamuse.com/words?max=%d&ml=%s&rel_rhy=%s",
            MAX_RESULTS,
            $context,
            $word
        );
    } else {
        $uri = sprintf(
            "http://api.datamuse.com/words?max=%d&rel_rhy=%s",
            MAX_RESULTS,
            $word
        );
    }

    print "URI: $uri\n" if $DEBUG;
    return $uri;
}
sub __placeholder {}

1;
__END__

=head1 NAME

Word::Rhymes - Takes a word and fetches rhyming matches from RhymeZone.com

=for html
<a href="http://travis-ci.com/stevieb9/words-rhyme"><img src="https://www.travis-ci.com/stevieb9/words-rhyme.svg?branch=master"/>
<a href='https://coveralls.io/github/stevieb9/words-rhyme?branch=master'><img src='https://coveralls.io/repos/stevieb9/words-rhyme/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 DESCRIPTION

Provides the ability to fetch words that rhyme with a word, while allowing for
context if desired (eg. find all words that rhyme with baseball that relate
to breakfast).

Ability to change sort order, minimum rhyme match score, maximum number of
words returned etc.

=head1 SYNOPSIS

    use Word::Rhymes;

    my $wr = Word::Rhymes->new;

    # Print all matching rhyming words that have three syllables

    my $rhyming_words = $wr->fetch('disdain');
    print "$_\n" for @{ $rhyming_words->{3} };

    # With context (rhymes with 'disdain', but only words relating to 'farm')

    $rhyming_words = $wr->fetch('disdain', 'farm');

    # Simply display the output

    $wr->print('disdain', 'farm');

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS/FUNCTIONS

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
