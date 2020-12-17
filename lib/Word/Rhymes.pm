package Word::Rhymes;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak);
use JSON;
use HTTP::Request;
use LWP::UserAgent;

use constant {
    DEBUG => 1,
};

my $ua = LWP::UserAgent->new;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->_args(\%args);

    return $self;
}
sub fetch {
    my ($self, $word) = @_;

    if (! defined $word) {
        croak("fetch() needs a word sent in");
    }

    my $req = HTTP::Request->new('GET', $self->uri($word));

    my $response = $ua->request($req);

    if ($response->is_success) {
        my $data = decode_json $response->decoded_content;

        my @rhyming_words;

        for (@$data) {
            say "$_->{word}: $_->{score}" if $_->{score} >= $self->min_score && DEBUG;
            push @rhyming_words, "$_->{word}" if $_->{score} >= $self->min_score;
        }

        return \@rhyming_words;
    }
    else {
        print "Invalid response\n\n";
        return undef;
    }
}
sub uri {
    my ($self, $word) = @_;
    my $uri = sprintf(
        "https://rhymebrain.com/talk?function=getRhymes&word=%s&maxResults=%d",
        $word,
        $self->max_results
    );

    print "URI: $uri\n" if DEBUG;
    return $uri;
}
sub max_results {
    my ($self, $max) = @_;

    if (defined $max) {
        croak("max_results must be an integer")
            if $max !~ /^\d+$/;
        croak("max_results must be between 1-1000")
            if $max < 1 && $max > 1000;

        $self->{max_results} = $max;
    }

    return $self->{max_results} // 20;
}
sub min_score {
    my ($self, $min) = @_;

    if (defined $min) {
        croak("min_score must be an integer")
            if $min !~ /^\d+$/;
        croak("min-score must be between 1-300")
            if $min < 1 && $min > 300;

        $self->{min_score} = $min;
    }

    return $self->{min_score} // 300;
}
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
}
sub __placeholder {}

1;
__END__

=head1 NAME

Word::Rhymes - Takes a word and fetches rhyming matches from rhymebrain.com

=for html
<a href="http://travis-ci.com/stevieb9/words-rhyme"><img src="https://www.travis-ci.com/stevieb9/words-rhyme.svg?branch=master"/>
<a href='https://coveralls.io/github/stevieb9/words-rhyme?branch=master'><img src='https://coveralls.io/repos/stevieb9/words-rhyme/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Word::Rhymes;

    my $foo = Word::Rhymes->new();
    ...

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
