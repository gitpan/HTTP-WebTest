# $Id: SetRequest.pm,v 1.1.2.20 2002/01/03 16:13:20 ilya Exp $

package HTTP::WebTest::Plugin::SetRequest;

=head1 NAME

HTTP::WebTest::Plugin::SetRequest - Initializes test HTTP request

=head1 SYNOPSYS

Not Applicable

=head1 DESCRIPTION

This plugin initializes test HTTP request.

=cut

use strict;
use URI;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=head2 url

URL to test. If schema is omitted then HTTP is implied.

=head2 method

HTTP request method.

=head3 Allowed values

C<GET>, C<PUT>

=head3 Default value

C<GET>

=head2 params

A list of name/value pairs to be passed as parameters to the
URL. (This element is used to test pages that process input from
forms.) Unless the method key is set to C<POST>, these pairs are
URI-escaped and appended to the requested URL.

=head2 auth

A list of userid/password pairs to be used for web page access
authorization.

=head2 proxies

A list of service name/proxy URL pairs that specify proxy servers to
use for requests.

For example (C<wtscript> usage):

    proxies = ( http => http://http_proxy.mycompany.com
                ftp  => http://ftp_proxy.mycompany.com )

=head2 pauth

A list of userid/password pairs to be used for proxy server access
authorization.

=cut

sub param_types {
    return { qw(url     uri
	        method  string
                params  hashlist
	        auth    list
	        proxies hashlist
	        pauth   list) };
}

sub validate_test {
    my $self = shift;
    my $test = shift;

    my %checks = $self->SUPER::validate_test($test);

    if(exists $checks{method}) {
	$checks{method} &&=
	    $self->test_result($test->param('method') =~ /^(?:GET|POST)$/i ? 1 : 0,
			       'Request method should be either GET or POST.');
    }
    if(exists $checks{auth}) {
	$checks{auth} &&=
	    $self->test_result(@{$test->param('auth')} == 2,
			       'Parameter auth should have two elements.');
    }
    if(exists $checks{pauth}) {
 	$checks{pauth} &&=
 	    $self->test_result(@{$test->param('pauth')} == 2,
 			       'Parameter auth should have two elements.');
    }

    return %checks;
}

sub prepare_request {
    my $self = shift;

    # get user agent object
    my $user_agent = $self->webtest->user_agent;

    # get request object
    my $request = $self->webtest->last_request;

    # get various params we handle
    my $url = $self->test_param('url');
    my $method = $self->test_param('method');
    my $params = $self->test_param('params');
    my $auth = $self->test_param('auth');
    my $proxies = $self->test_param('proxies');
    my $pauth = $self->test_param('pauth');

    # fix broken url
    if(defined $url) {
	$url = "http://" . $url unless $url =~ m|^\w+://|;
    }

    # set request uri
    $request->uri($url) if defined $url;

    # set request method (with default GET)
    if(defined $method) {
	if($method =~ /^POST$/i) {
	    $request->method('POST');
	} else {
	    $request->method('GET');
	}
    } else {
	$request->method('GET');
    }

    # set request params
    if(defined $params) {
	# We use a temporary URI object to format
	# the application/x-www-form-urlencoded content.
	my $url = URI->new('http:');
	$url->query_form(@$params);
	my $query = $url->query;

	if($request->method eq 'GET') {
	    $request->uri->query($query);
	} elsif($request->method eq 'POST') {
	    $request->content($query);
	    $request->header('Content-Length' => length $query);
	}
    }

    # pass authorization data
    if(defined $auth) {
	$request->authorization_basic(@$auth);
    }

    # set proxies
    if(defined $proxies) {
	for my $i (0 .. @$proxies / 2 - 1) {
	    $user_agent->proxy(@$proxies[2 * $i, 2 * $i + 1]);
	}
    }

    # pass proxy authorization data
    if(defined $pauth) {
	$request->proxy_authorization_basic(@$pauth);
    }
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
