# $Id: Cookies.pm,v 1.2 2002/02/02 04:08:19 m_ilya Exp $

package HTTP::WebTest::Plugin::Cookies;

=head1 NAME

HTTP::WebTest::Plugin::Cookies - Send and recieve cookies in tests

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin provides means to control sending and recieve cookies in
web test.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

use HTTP::Status;

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 accept_cookies

Option to accept cookies from the web server.

These cookies exist only while the program is executing and do not
affect subsequent runs. These cookies do not affect your browser or
any software other than the test program. These cookies are only
accessible to other tests executed during test sequence execution.

See also the <send_cookies> parameter.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<yes>

=head2 send_cookies

Option to send cookies to web server. This applies to cookies received
from the web server or cookies specified using the C<cookies> test
parameter.

This does NOT give the web server(s) access to cookies created with a
browser or any user agent software other than this program. The
cookies created while this program is running are only accessible to
other tests in the same test sequence.

See also the <accept_cookies> parameter.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<yes>

=head2 cookie

Synonym to C<cookies>.

=head2 cookies

Specifies a cookie(s) to send to the web server.

Each cookie is specified by following list:

    ( version
      name
      value
      path
      domain
      port
      path_spec
      secure
      maxage
      discard
      name1
      value1
      name2
      value2
      ...
    )


Any element not marked below as REQUIRED may be defaulted by
specifying a null value or ''.

=over 4

=item * version (REQUIRED)

Version number of cookie spec to use, usually 0.

=item * name (REQUIRED)

Name of cookie. Cannot begin with a $ character.

=item * value (REQUIRED)

Value of cookie.

=item * path (REQUIRED)

URL path name for which this cookie applies. Must begin with a /
character.  See also path_spec.

=item * domain (REQUIRED)

Domain for which cookie is valid. (REQUIRED). Should begin with a
period.  Must either contain two periods or be equal to C<.local>.

=item * port

List of allowed port numbers that the cookie may be returned to.  If
not specified, cookie can be returned to any port.  Must be specified
using the format C<N> or C<N, N, ..., N> where N is one or more
digits.

=item * path_spec

Ignored if version is less than 1.  Option to ignore the value of
path.  Default value is 0.

=over 4

=item * 1

Use the value of path.

=item * 0

Ignore the specified value of path.

=back

=item * secure

Option to require secure protocols for cookie transmission.  Default
value is 0.

=over 4

=item * 1

Use only secure protocols to transmit this cookie.

=item * 0

Secure protocols are not required for transmission.

=back

=item * maxage

Number of seconds until cookie expires.

=item * discard

Option to discard cookie when the program finishes.  Default 0. (The
cookie will be discarded regardless of the value of this element.)

=over 4

=item * 1

Discard cookie when the program finishes.

=item * 0

Don't discard cookie.

=back

=item * name/value

Zero, one or several name/value pairs may be specified. The name
parameters are words such as Comment or CommentURL and the value
parameters are strings that may contain embedded blanks.

=back

An example cookie would look like:

    ( 0
      WebTest cookie #1
      expires&2592000&type&consumer
      /
      .unixscripts.com
      ''
      0
      0
      200
      1
    )

See RFC 2965 for details (ftp://ftp.isi.edu/in-notes/rfc2965.txt).

=head3 Usage in wtscript files

You may specify multiple cookies within each test block by specifying
multiple instances of the C<cookies> parameter.

=head3 Usage in Perl scripts

Use arrayref of arrayrefs containing cookies to pass with the HTTP
request.

Each array must have at least 5 elements; if the number of elements is
over 10 it must have an even number of elements.

=cut

sub param_types {
    return q(accept_cookies yesno
             send_cookies   yesno
             cookie         list
             cookies        list);
}

use constant NCOOKIE_REFORMAT => 10;

sub prepare_request {
    my $self = shift;

    $self->validate_params(qw(accept_cookies send_cookies
                              cookies cookie));

    my $accept_cookies = $self->yesno_test_param('accept_cookies', 1);
    my $send_cookies = $self->yesno_test_param('send_cookies', 1);
    my $cookies = $self->test_param('cookies');
    $cookies ||= $self->test_param('cookie'); # alias for parameter
    $cookies = $self->transform_cookies($cookies) if defined $cookies;

    my $cookie_jar = $self->webtest->user_agent->cookie_jar;

    # configure cookie jar
    $cookie_jar->accept_cookies($accept_cookies);
    $cookie_jar->send_cookies($send_cookies);

    if(defined $cookies) {
	for my $cookie (@$cookies) {
	    $cookie_jar->set_cookie(@$cookie);
	}
    }
}

sub check_response {
    my $self = shift;

    # we don't check here anything - just some clean up
    my $cookie_jar = $self->webtest->user_agent->cookie_jar;
    delete $cookie_jar->{accept_cookies};
    delete $cookie_jar->{send_cookies};

    return ();
}

# transform cookies to some canonic representation
sub transform_cookies {
    my $self = shift;
    my $cookies = shift;

    # check if $cookies is list of list
    unless(ref($$cookies[0]) eq 'ARRAY') {
	return $self->transform_cookies([ $cookies ]);
    }

    my @new_cookies = ();

    for my $cookie (@$cookies) {
	# make copy of cookie (missing fields are set to undef)
	my @new_cookie = @$cookie[0 .. NCOOKIE_REFORMAT - 1];

        # replace '' with undef
	@new_cookie = map +(defined($_) and $_ eq '') ? (undef) : $_,
                      @new_cookie;

	# collect all additional attributes (name, value pairs)
	my @extra = @$cookie[ NCOOKIE_REFORMAT .. @$cookie - 1];
	push @new_cookie, { @extra };

	push @new_cookies, \@new_cookie;
    }

    return \@new_cookies;
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
