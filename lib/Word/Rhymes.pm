package Word::Rhymes;

use strict;
use warnings;

our $VERSION = '0.01';

use JSON;
use HTTP::Request;
use LWP::UserAgent;

use constant DEBUG => 0;

my $max_results = 50;
my $min_score = 300;

die "Need param!\n" if ! @ARGV;
my $word = $ARGV[0];

my $uri = "https://rhymebrain.com/talk?function=getRhymes&word=$word&maxResults=$max_results";

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new( 'GET', $uri );

my $response = $ua->request($req);

if ($response->is_success) {
    my $orig = $response->decoded_content;
    my $data = decode_json $response->decoded_content;

    for (@$data) {
        say "$_->{word}: $_->{score}" if $_->{score} >= $min_score && DEBUG;
        say "$_->{word}" if $_->{score} >= $min_score;
    }
}
else {
    print "Invalid response\n\n";
}

sub __placeholder {}

1;
__END__

=head1 NAME

Word::Rhymes - The great new Word::Rhymes!

=for html
<a href="http://travis-ci.com/stevieb9/words-rhyme"><img src="https://www.travis-ci.com/stevieb9/words-rhyme.svg?branch=master"/>
<a href='https://coveralls.io/github/stevieb9/words-rhyme?branch=master'><img src='https://coveralls.io/repos/stevieb9/words-rhyme/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

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
