#!/usr/bin/perl -w

# $Id: 12-request.t,v 1.3 2002/07/31 15:26:23 m_ilya Exp $

# Unit tests for HTTP::WebTest::Request

use strict;
use Test;

BEGIN { plan tests => 25 }

use HTTP::WebTest::Request;

# test constructor
my $REQUEST;
{
    $REQUEST = HTTP::WebTest::Request->new;
    ok(defined $REQUEST);
    ok($REQUEST->isa('HTTP::WebTest::Request'));
    ok($REQUEST->isa('HTTP::Request'));
}

# test base_uri() and uri()
{
    for my $uri (qw(http://test1 http://a.a.a http://www.a.b)) {
	$REQUEST->base_uri($uri);
	ok($REQUEST->base_uri eq $uri);
	ok($REQUEST->uri eq $uri);
    }
}

# check that uri() returns URI object
{
    $REQUEST->base_uri('http://test2');
    my $uri = $REQUEST->uri;
    ok($uri->isa('URI'));
    ok($uri->host eq 'test2');
}

# check that alias url() work too
{
    $REQUEST->base_uri('http://test3');
    my $uri = $REQUEST->url;
    ok($uri->isa('URI'));
    ok($uri->host eq 'test3');
}

# set/get query params via params()
{
    # default value
    ok(join(' ', @{$REQUEST->params}) eq '');

    $REQUEST->params([a => 'b']);
    ok(join(' ', @{$REQUEST->params}) eq 'a b');

    $REQUEST->params([d => 'xy', 1 => 2]);
    ok(join(' ', @{$REQUEST->params}) eq 'd xy 1 2');
}

# test setting uri via uri()
{
    $REQUEST->base_uri('http://a');
    $REQUEST->uri('http://b');
    ok($REQUEST->uri eq 'http://b');

    $REQUEST->uri('http://c?x=y');
    ok($REQUEST->uri eq 'http://c');
    ok(join(' ', @{$REQUEST->params}) eq 'x y');
}

# set some params and watch uri() to change for GET request
{
    $REQUEST->params([a => 'b']);
    $REQUEST->base_uri('http://a');
    $REQUEST->method('GET');
    ok($REQUEST->uri eq 'http://a?a=b');
    ok(${$REQUEST->content_ref} eq '');
}

# set some params and watch content_ref() to change for POST request
{
    $REQUEST->params([a => 'b']);
    $REQUEST->base_uri('http://a');
    $REQUEST->method('POST');
    ok($REQUEST->uri eq 'http://a');
    ok(${$REQUEST->content_ref} eq 'a=b');
}

# use array refs as param values and check if file upload request is
# created
{
    $REQUEST->params([a => ['t/12-request.t']]);
    $REQUEST->base_uri('http://a');
    $REQUEST->method('POST');
    ok($REQUEST->uri eq 'http://a');
    ok(${$REQUEST->content_ref} =~ 'Content-Disposition: form-data; name="a".*; filename="12-request.t');
}
