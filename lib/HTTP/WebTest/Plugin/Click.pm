# $Id: Click.pm,v 1.9 2002/05/15 19:27:53 m_ilya Exp $

package HTTP::WebTest::Plugin::Click;

=head1 NAME

HTTP::WebTest::Plugin::Click - Click buttons and links on web page

=head1 SYNOPSIS

    plugins = ( ::Click )

    test_name = Some test
        click_link = Name of the link
    end_test

    test_name = Another test
        click_button = Name of the button
    end_test

=head1 DESCRIPTION

This plugin allows to use names of links and button on HTML pages to
build test requests.

=cut

use strict;
use HTML::TokeParser;
use URI;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy opt_params

=head2 click_button

Given name of submit button (i.e. C<<input type="submit"E<gt>> tag
inside of C<<formE<gt>> tag) on previosly requested HTML page builds
test request to the submitted page.

Note that you still need to pass all form parameters yourself using
C<params> test parameter.

=head3 Example

See example in L<HTTP::WebTest::Cookbook|HTTP::WebTest::Cookbook>.

=head2 click_link

Given name of link (i.e. C<<aE<gt>> tag) on previosly requested HTML
page builds test request to the linked page.

=head3 Example

See example in L<HTTP::WebTest::Cookbook|HTTP::WebTest::Cookbook>.

=cut

sub param_types {
    return q(click_button scalar
             click_link   scalar);
}

sub prepare_request {
    my $self = shift;

    $self->validate_params(qw(click_button click_link));

    # get current request object
    my $request = $self->webtest->last_request;

    # get number of previous test if any
    my $prev_test_num = $self->webtest->last_test_num - 1;
    return if $prev_test_num < 0;

    # get previous response object
    my $response = $self->webtest->tests->[$prev_test_num]->response;

    # no response - nothing to do
    return unless defined $response;

    # do nothing unless it is HTML
    return unless $response->content_type eq 'text/html';

    # get various params we handle
    my $click_button = $self->test_param('click_button');
    my $click_link   = $self->test_param('click_link');

    if(defined $click_link) {
	# find matching link
	my $link = $self->find_link(response => $response,
				    pattern  => $click_link);

	$self->new_request_uri(request => $request, uri => $link)
	    if defined $link;
    } elsif(defined $click_button) {
	# find action which corresponds to requested submit button
	my $action = $self->find_form(response => $response,
				      pattern  => $click_button);

	$self->new_request_uri(request => $request, uri => $action)
	    if defined $action;
    }
}

# sets new request URI preserving query parameters if necessary
sub new_request_uri {
    my $self = shift;
    my %param = @_;

    my $request = $param{request};
    my $uri     = $param{uri};

    my $old_query = undef;
    if($request->method eq 'GET') {
	$old_query = $request->uri->query;
    }
    # set request uri
    $request->uri($uri);
    # restore query parameters
    if(defined $old_query) {
	my $new_query = $request->uri->query;
	$new_query = defined $new_query ? "$new_query&$old_query" : $old_query;
	$request->uri->query($new_query);
    }
}

sub find_base {
    my $self = shift;
    my $response = shift;

    my $base = $response->base;
    my $content = $response->content;

    # look for base tag inside of head tag
    my $parser = HTML::TokeParser->new(\$content);
    my $token = $parser->get_tag('head');
    if(defined $token) {
	$token = $parser->get_tag('base', '/head');
	if($token->[0] eq 'base') {
	    $base = $token->[1]{href};
	}
    }

    return $base;
}

sub find_link {
    my $self = shift;
    my %param = @_;

    my $response = $param{response};
    my $pattern  = $param{pattern};

    my $base    = $self->find_base($response);
    my $content = $response->content;

    # look for matching link tag
    my $parser = HTML::TokeParser->new(\$content);
    my $link = undef;
    while(my $token = $parser->get_tag('a')) {
	my $uri = $token->[1]{href};
	next unless defined $uri;
	if($token->[0] eq 'a') {
	    my $text = $parser->get_trimmed_text('/a');
	    if($text =~ /$pattern/i) {
		$link = $uri;
		last;
	    }
	}
    }

    # we haven't found anything
    return unless defined $link;

    # return link
    return URI->new_abs($link, $base);
}

sub find_form {
    my $self = shift;
    my %param = @_;

    my $response = $param{response};
    my $pattern  = $param{pattern};

    my $base    = $self->find_base($response);
    my $content = $response->content;

    # look for form
    my $parser = HTML::TokeParser->new(\$content);
    my $uri = undef;
  FORM:
    while(my $token = $parser->get_tag('form')) {
	# get action from form tag param
	my $action = $token->[1]{action} || $base;

	# find matching submit button or end of form
	while(my $token = $parser->get_tag('input', '/form')) {
	    my $tag = $token->[0];

	    if($tag eq '/form') {
		# end of form: let's look for another form
		next FORM;
	    }

	    # check if right input control is found
	    my $type = $token->[1]{type} || 'text';
	    my $name = $token->[1]{name} || '';
	    my $value = $token->[1]{value} || '';
	    next if $type !~ /^submit$/i;
	    next if $name !~ /$pattern/i and $value !~ /$pattern/i;

	    # stop searching
	    $uri = $action;
	    last FORM;
	}
    }

    # we haven't found anything
    return unless defined $uri;

    # return method and link
    return URI->new_abs($uri, $base);
}

=head1 COPYRIGHT

Copyright (c) 2001,2002 Ilya Martynov.  All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
