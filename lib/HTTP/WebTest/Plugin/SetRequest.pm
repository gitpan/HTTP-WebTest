# $Id: SetRequest.pm,v 1.6 2002/02/12 13:09:18 m_ilya Exp $

package HTTP::WebTest::Plugin::SetRequest;

=head1 NAME

HTTP::WebTest::Plugin::SetRequest - Initializes test HTTP request

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin initializes test HTTP request.

=cut

use strict;
use URI;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 url

URL to test. If schema part of URL is omitted (i.e. URL doesn't start
with C<http://>, C<ftp://>, etc) then C<http://> is implied.

=head2 method

HTTP request method.

See RFC 2616 (HTTP/1.1 protocol).

=head3 Allowed values

C<GET>, C<PUT>

=head3 Default value

C<GET>

=head2 params

A list of name/value pairs to be passed as parameters to the
URL. (This element is used to test pages that process input from
forms.) Unless the method key is set to C<POST>, these pairs are
URI-escaped and appended to the requested URL.

For example,

    url = http://www.hotmail.com/cgi-bin/hmhome
    params = ( curmbox
               F001 A005
               from
               HotMail )

generates the HTTP request:

    http://www.hotmail.com/cgi-bin/hmhome?curmbox=F001%20A005&from=HotMail

The names and values will be URI-escaped as defined by RFC 2396.

=head2 auth

A list which contains two elements: userid/password pair to be used
for web page access authorization.

=head2 proxies

A list of service name/proxy URL pairs that specify proxy servers to
use for requests.

For example (C<wtscript> usage):

    proxies = ( http => http://http_proxy.mycompany.com
                ftp  => http://ftp_proxy.mycompany.com )

=head2 pauth

A list which contains two elements: userid/password pair to be used
for proxy server access authorization.

=head2 user_agent

Set the product token that is used to identify the user agent on
the network.

=head3 Default value

C<HTTP-WebTest/NN>

where C<NN> is version number of HTTP-WebTest.

=cut

sub param_types {
    return q(url        uri
	     method     scalar('^(?:GET|POST)$')
 	     params     hashlist
	     auth       list('scalar','scalar')
	     proxies    hashlist
	     pauth      list('scalar','scalar')
             user_agent scalar);
}

sub prepare_request {
    my $self = shift;

    # get user agent object
    my $user_agent = $self->webtest->user_agent;

    # get request object
    my $request = $self->webtest->last_request;

    $self->validate_params(qw(url method params
                              auth proxies pauth
                              user_agent));

    # get various params we handle
    my $url     = $self->test_param('url');
    my $method  = $self->test_param('method');
    my $params  = $self->test_param('params');
    my $auth    = $self->test_param('auth');
    my $proxies = $self->test_param('proxies');
    my $pauth   = $self->test_param('pauth');
    my $ua_name = $self->test_param('user_agent');

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
	my @params = ref($params) eq 'ARRAY' ? @$params : %$params;
	$url->query_form(@params);
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

    # set user agent name
    $ua_name = 'HTTP-WebTest/' . HTTP::WebTest->VERSION
	unless defined $ua_name;
    $user_agent->agent($ua_name);
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
