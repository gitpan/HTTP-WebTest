# $Id: StatusTest.pm,v 1.1.1.1 2002/01/24 12:26:29 m_ilya Exp $

package HTTP::WebTest::Plugin::StatusTest;

=head1 NAME

HTTP::WebTest::Plugin::StatusTest - Checks HTTP response status

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin checks HTTP response status.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

use HTTP::Status;

=head1 TEST PARAMETERS

None.

=cut

sub check_response {
    my $self = shift;

    my $code = $self->webtest->last_response->code;
    my $status_line = $self->webtest->last_response->status_line;

    my $ok = $code eq RC_OK;
    my $comment = $status_line;

    return ['Status code check', $self->test_result($ok, $comment)];
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
