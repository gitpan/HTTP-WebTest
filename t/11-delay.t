#!/usr/bin/perl -w

# $Id: 11-delay.t,v 1.2 2002/07/25 08:33:16 m_ilya Exp $

# This script tests HTTP::WebTest::Plugin::Delay plugin

use strict;
use HTTP::Status;
use Test;

use HTTP::WebTest;
use Time::HiRes qw(gettimeofday);

require 't/config.pl';
require 't/utils.pl';

use vars qw($HOSTNAME $PORT $URL $TEST);

BEGIN { plan tests => 4 }

# init tests
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;
my $OPTS = { plugins => [ '::Delay' ] };


# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

{
    # run non-empty test once to trigger loading of all modules;
    # otherwise next test run takes too much time (because of module
    # loading) and breaks delay test

    my $output = '';

    $WEBTEST->run_tests([ { url => abs_url($URL, '/test') } ],
			{ %$OPTS,
			  output_ref => \$output });
}

{
    if(defined $ENV{TEST_FAST}) {
	for (1..2) {
	    skip('skip: delay tests are disabled', 1);
	}
    } else {
	my $start = gettimeofday;

	my $tests = [ { url => abs_url($URL, '/test'),
			delay => 2 } ];

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      opts => $OPTS,
		      tests => $tests,
		      check_file => 't/test.out/delay');

	my $delay = gettimeofday - $start;
	ok(1 < $delay and $delay < 3);
    }
}

{
    if(defined $ENV{TEST_FAST}) {
	for (1..2) {
	    skip('skip: delay tests are disabled', 1);
	}
    } else {
	my $start = gettimeofday;

	my $tests = [ { url => abs_url($URL, '/test'),
			delay => 4 } ];

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      opts => $OPTS,
		      tests => $tests,
		      check_file => 't/test.out/delay');

	my $delay = gettimeofday - $start;
	ok(3 < $delay and $delay < 5);
    }
}

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    $connect->send_error(RC_NOT_FOUND);
}
