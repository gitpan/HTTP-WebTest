package Bundle::HTTP::WebTest;

# $Id: WebTest.pm,v 1.3 2002/06/19 10:28:21 m_ilya Exp $

$VERSION = '0.01';

=head1 NAME

Bundle::HTTP::WebTest - a bundle to install HTTP::WebTest

=head1 SYNOPSIS

    perl -MCPAN -e 'install Bundle::HTTP::WebTest'

=head1 CONTENTS

Algorithm::Diff - only required to run C<make test>

CGI::Cookie

File::Temp

LWP

MIME::Base64

Net::SMTP

Text::Balanced

Pod::Usage

Pod::Man

Time::HiRes

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
