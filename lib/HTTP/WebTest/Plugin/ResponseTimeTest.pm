# $Id: ResponseTimeTest.pm,v 1.1.2.9 2002/01/13 02:47:58 ilya Exp $

package HTTP::WebTest::Plugin::ResponseTimeTest;

=head1 NAME

HTTP::WebTest::Plugin::ResponseTimeTest - Tests for response time

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin provides support for response time tests.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=head2 min_rtime

Minimum web server response time (seconds) expected.

=head3 Allowed values

Any number less than C<max_rtime> (if C<max_rtime> is specified).

=head2 max_rtime

Maximum web server response time (seconds) expected.

=head3 Allowed values

Any number greater that zero and greater than C<min_rtime> (if
C<min_rtime> is specified).

=cut

sub param_types {
    return { qw(min_rtime string
                max_rtime string) };
}

sub check_response {
    my $self = shift;

    # response time
    my $rtime = $self->webtest->last_response_time;

    # response time limits
    my $min_rtime = $self->test_param('min_rtime');
    my $max_rtime = $self->test_param('max_rtime');

    # test results
    my @results = ();
    my @ret = ();

    # check minimal size
    if(defined $min_rtime) {
	my $ok = $rtime >= $min_rtime;
	my $comment = 'Response time (';
	$comment .=  sprintf '%6.2f', $rtime;
	$comment .= ' ) is > or =';
	$comment .= sprintf '%6.2f', $min_rtime;
	$comment .= ' ?';

	push @results, $self->test_result($ok, $comment);
    }

    # check maximal size
    if(defined $max_rtime) {
	my $ok = $rtime <= $max_rtime;
	my $comment = 'Response time (';
	$comment .=  sprintf '%6.2f', $rtime;
	$comment .= ' ) is < or =';
	$comment .= sprintf '%6.2f', $max_rtime;
	$comment .= ' ?';

	push @results, $self->test_result($ok, $comment);
    }

    push @ret, [ 'Response time check', @results ] if @results;

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
