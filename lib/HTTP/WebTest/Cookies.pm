# $Id: Cookies.pm,v 1.1.1.1 2002/01/24 12:26:24 m_ilya Exp $

package HTTP::WebTest::Cookies;

=head1 NAME

HTTP::WebTest::Cookies - Cookie storage and management

=head1 SYNOPSIS

    use HTTP::WebTest::Cookies;

    $cookie_jar = HTTP::WebTest::Cookies->new;

    $cookie_jar->accept_cookies($bool);
    $cookie_jar->send_cookies($bool);

    $cookie_jar->add_cookie_header($request);
    $cookie_jar->extract_cookies($response);

=head1 DESCRIPTION

Subclass of L<HTTP::Cookies|HTTP::Cookies> which enables optional
transmission and receipt of cookies.

=head1 METHODS

=cut

use strict;

use base qw(HTTP::Cookies);

use HTTP::WebTest::Utils qw(make_access_method);

=head2 accept_cookies($optional_accept_cookies)

Enables or disables receipt of cookies if boolean parameter
C<$optional_accept_cookies> is passed.

=head3 Returns

True if receipt of cookies is enabled; false otherwise.

=cut

*accept_cookies = make_access_method('ACCEPT_COOKIES');

=head2 send_cookies($optional_send_cookies)

Enables or disables transmission of cookies if boolean parameter
C<$optional_send_cookies> is passed.

=head3 Returns

True if transmission of cookies is enabled; false otherwise.

=cut

*send_cookies = make_access_method('SEND_COOKIES');

=head2 extract_cookies (...)

Overloaded method. Passes all arguments to C<SUPER::extract_cookies>
if receipt of cookies is enabled. Does nothing otherwise.

=cut

sub extract_cookies {
    my $self = shift;
    if($self->accept_cookies) { $self->SUPER::extract_cookies(@_); }
}

=head2 add_cookie_header (...)

Overloaded method. Passes all arguments to C<SUPER::add_cookie_header>
if transmission of cookies is enabled. Does nothing otherwise.

=cut

sub add_cookie_header {
    my $self = shift;
    if($self->send_cookies) { $self->SUPER::add_cookie_header(@_); }
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson. All rights reserved.

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::Cookies|HTTP::Cookies>

=cut

1;
