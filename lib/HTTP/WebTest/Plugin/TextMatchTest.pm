# $Id: TextMatchTest.pm,v 1.1.2.12 2002/01/15 17:16:08 ilya Exp $

package HTTP::WebTest::Plugin::TextMatchTest;

=head1 NAME

HTTP::WebTest::Plugin::TextMatchTest - Response body checks

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin provides test parameters that allow to check response
body. It supports regexps and literal string searches.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=head2 ignore_case

Option to do case-insensitive string matching for C<text_forbid>,
C<text_require>, C<regex_forbid> and C<regex_require> test parameters.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 text_forbid

List of text strings that are forbidden to use exist in the returned
page.

=head2 text_require

List of text strings that are required to use exist in the returned
page.

=head2 regex_forbid

List of regular expressions that are URI forbidden to exist in the
returned page.

=head2 regex_require

List of regular expressions that are URI required to exist in the
returned page.

=cut

sub param_types {
    return { qw(ignore_case   yesno
                text_forbid   list
                text_require  list
                regex_forbid  list
                regex_require list) };
}

sub check_response {
    my $self = shift;

    # response content
    my $content = $self->webtest->last_response->content;

    # ignore case or not?
    my $ignore_case = $self->yesno_test_param('ignore_case');
    my $case_re = $ignore_case ? '(?i)' : '';

    # test results
    my @results = ();
    my @ret = ();

    # check for forbidden text
    for my $text_forbid (@{$self->test_param('text_forbid', [])}) {
	my $ok = $content !~ /$case_re\Q$text_forbid\E/;

	push @results, $self->test_result($ok, $text_forbid);
    }

    push @ret, ['Forbidden text', @results] if @results;
    @results = ();

    # check for required text
    for my $text_require (@{$self->test_param('text_require', [])}) {
	my $ok = $content =~ /$case_re\Q$text_require\E/;

	push @results, $self->test_result($ok, $text_require);
    }

    push @ret, ['Required text', @results] if @results;
    @results = ();

    # check for forbidden regex
    for my $regex_forbid (@{$self->test_param('regex_forbid', [])}) {
	my $ok = $content !~ /$case_re$regex_forbid/;

	push @results, $self->test_result($ok, $regex_forbid);
    }

    push @ret, ['Forbidden regex', @results] if @results;
    @results = ();

    # check for required regex
    for my $regex_require (@{$self->test_param('regex_require', [])}) {
	my $ok = $content =~ /$case_re$regex_require/;

	push @results, $self->test_result($ok, $regex_require);
    }

    push @ret, ['Required regex', @results] if @results;
    @results = ();

    return @ret;
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson. All rights reserved.

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
