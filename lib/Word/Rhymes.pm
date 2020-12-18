package Word::Rhymes;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak);
use JSON;
use HTTP::Request;
use LWP::UserAgent;

my $DEBUG = $ENV{WORD_RHYMES_DEBUG};

use constant {
    # Limits
    MIN_SCORE           => 0,
    MAX_SCORE           => 1000000,
    MAX_RESULTS         => 1000,

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

    print "Word: $word, Context: $context\n" if $DEBUG;

    if (! defined $word) {
        croak("fetch() needs a word sent in");
    }
    if (defined $context && $context !~ /[a..zA..Z-]/) {
        croak("context parameter must be an alpha word only.");
    }

    my $req = HTTP::Request->new('GET', $self->_uri($word, $context));

    my $response = $ua->request($req);

    if ($response->is_success) {
        my $data = decode_json $response->decoded_content;

        my @sorted = sort {$b->{numSyllables} <=> $a->{numSyllables}} @$data;
        my %organized;

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
        if ($max < 1 || $max > MAX_RESULTS) {
            croak("max_results must be between  1-1000")
        }
        $self->{max_results} = $max;
    }

    return $self->{max_results} // MAX_RESULTS;
}
sub min_score {
    my ($self, $min) = @_;

    if (defined $min) {
        croak("min_score must be an integer") if $min !~ /^-?\d+$/;
        if ($min < 0 || $min > MAX_SCORE) {
            croak("min_score must be between 0-100,000,000");
        }
        $self->{min_score} = $min;
    }

    return $self->{min_score} // MIN_SCORE;
}
sub print {
    my ($self, $word, $context) = @_;

    my $rhyming_words = $self->fetch($word, $context);

    #FIXME: Change below to hash, isolate each numSyllable arrays

    my $max_word_len
        = length((sort { length $b <=> length $a} @$rhyming_words)[0]);
    my $column_width = $max_word_len + 3;

    my $columns = $column_width > 15 ? 5 : 6;

    if ($DEBUG) {
        printf "matched word count: %d\n", scalar @$rhyming_words;
        printf "column width: %d, column count: %d\n", $column_width, $columns;
    }

    print defined $context
        ? "\nRhymes with '$word' related to '$context'\n\n}"
        : "\nRhymes with '$word'\n\n";

    for (0..$#$rhyming_words) {
        print "\n" if $_ % $columns == 0 && $_ != 0;
        printf("%-*s", $column_width, $rhyming_words->[$_]);
    }
    print "\n";
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
