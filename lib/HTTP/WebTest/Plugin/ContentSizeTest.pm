# $Id: ContentSizeTest.pm,v 1.1.2.11 2002/01/13 02:47:58 ilya Exp $

package HTTP::WebTest::Plugin::ContentSizeTest;

=head1 NAME

HTTP::WebTest::Plugin::ContentSizeTest - Response body size checks

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin provides http response body size checks.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=head2 min_bytes

Minimum number of bytes expected in returned page.

=head3 Allowed Values

Any integer less than C<max_bytes> (if C<max_bytes> is specified).

=head2 max_bytes

Maximum number of bytes expected in returned page.

=head3 Allowed Values

Any integer greater that zero and greater than C<min_bytes> (if
C<min_bytes> is specified).

=cut

sub param_types {
    return { qw(min_bytes string
                max_bytes string) };
}

sub check_response {
    my $self = shift;

    # response content length
    my $nbytes = length $self->webtest->last_response->content;

    # size limits
    my $min_bytes = $self->test_param('min_bytes');
    my $max_bytes = $self->test_param('max_bytes');

    # test results
    my @results = ();
    my @ret = ();

    # check minimal size
    if(defined $min_bytes) {
	my $ok = $nbytes >= $min_bytes;
	my $comment = 'Number of returned bytes (';
	$comment .=  sprintf '%6d', $nbytes;
	$comment .= ' ) is > or =';
	$comment .= sprintf '%6d', $min_bytes;
	$comment .= ' ?';

	push @results, $self->test_result($ok, $comment);
    }

    # check maximal size
    if(defined $max_bytes) {
	my $ok = $nbytes <= $max_bytes;
	my $comment = 'Number of returned bytes (';
	$comment .=  sprintf '%6d', $nbytes;
	$comment .= ' ) is < or =';
	$comment .= sprintf '%6d', $max_bytes;
	$comment .= ' ?';

	push @results, $self->test_result($ok, $comment);
    }

    push @ret, [ 'Content size check', @results ] if @results;

    return @ret;
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson. All rights reserved.

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
