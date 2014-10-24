#!/usr/bin/perl -w

# $Id: 08-plugins.t,v 1.1.1.1 2002/01/24 12:26:17 m_ilya Exp $

# This script tests external plugin support in HTTP::WebTest.

use strict;
use HTTP::Status;
use Test;

use HTTP::WebTest;

require 't/config.pl';
require 't/utils.pl';

use lib 't';

use vars qw($HOSTNAME $PORT $URL);

BEGIN { plan tests => 3 }

# init tests
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;

# 1: tests with HelloWorld plugin
{
    my $opts = { plugins => [ 'HelloWorld' ] };

    my $tests = [ { url => abs_url($URL, '/hello') },
		  { url => abs_url($URL, '/no-hello') } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  opts => $opts,
		  tests => $tests,
		  check_file => 't/test.out/plugin-hello');
}

# 2: tests with HTTP::WebTest::Plugin::Counter plugin
{
    my $opts = { plugins => [ '::Counter' ] };

    my $tests = [ { url => abs_url($URL, '/hello') },
		  { url => abs_url($URL, '/no-hello') } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  opts => $opts,
		  tests => $tests,
		  check_file => 't/test.out/plugin-counter');
}

# 3: combined test with two plugins at same time
{
    my $opts = { plugins => [ 'HelloWorld',
			      'HTTP::WebTest::Plugin::Counter' ] };

    my $tests = [ { url => abs_url($URL, '/hello') },
		  { url => abs_url($URL, '/no-hello') } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  opts => $opts,
		  tests => $tests,
		  check_file => 't/test.out/plugin-hello-counter');
}

# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    my $path = $request->url->path;

    $connect->send_error(RC_NOT_FOUND);
}
