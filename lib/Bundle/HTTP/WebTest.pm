package Bundle::HTTP::WebTest;

# $Id: WebTest.pm,v 1.7 2002/12/14 16:55:16 m_ilya Exp $

$VERSION = '0.03';

=head1 NAME

Bundle::HTTP::WebTest - a bundle to install HTTP::WebTest

=head1 SYNOPSIS

    perl -MCPAN -e 'install Bundle::HTTP::WebTest'

=head1 CONTENTS

Algorithm::Diff - only required to run C<make test>

CGI::Cookie

Crypt::SSLeay - SSL support

HTTP::WebTest

LWP

MIME::Base64

Net::SMTP

Text::Balanced

Pod::Usage

Pod::Man

Time::HiRes

Test::Builder

Test::Builder::Tester - only required to run C<make test>

URI

=head1 DESCRIPTION

This bundle includes all modules required to run
L<HTTP::WebTest|HTTP::WebTest> using all bundled plugins. Also it
includes all modules required to run test suite for
L<HTTP::WebTest|HTTP::WebTest>.

=head1 COPYRIGHT

Copyright (c) 2002 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

=cut

1;
