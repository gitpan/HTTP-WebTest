#!/usr/bin/perl -w

# $Id: 09-hooks.t,v 1.2 2002/02/15 15:42:20 m_ilya Exp $

# This script tests HTTP::WebTest::Plugin::Hooks plugin

use strict;
use CGI::Cookie;
use HTTP::Response;
use HTTP::Status;
use IO::File;
use Test;

use HTTP::WebTest;

require 't/config.pl';
require 't/utils.pl';

use vars qw($HOSTNAME $PORT $URL $TEST);

BEGIN { plan tests => 7 }

# init tests
my $COUNTER_FILE = 't/counter';
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;
my $OPTS = { plugins => [ '::Hooks' ], default_report => 'no' };

# 1-3: test on_request parameter
{
    init_counter();

    my $counter_value = undef;

    my $tests1 = [ { url => abs_url($URL, '/inc_counter'),
		    on_request => sub { $counter_value = counter() } } ];

    $WEBTEST->run_tests($tests1, $OPTS);
    ok($counter_value == 0);
    ok(counter() == 1);

    init_counter();

    my $tests2 = [ { url => abs_url($URL, '/inc_counter'),
		     on_request => sub { inc_counter() } } ];

    $WEBTEST->run_tests($tests2, $OPTS);

    ok(counter() == 2);
}

# 4-6: test on_response parameter which doesn't returns any test results
{
    init_counter();

    my $counter_value = undef;

    my $tests1 = [ { url => abs_url($URL, '/inc_counter'),
		     on_response => sub { $counter_value = counter(); [] } } ];

    $WEBTEST->run_tests($tests1, $OPTS);
    ok($counter_value == 1);
    ok(counter() == 1);

    init_counter();

    my $tests2 = [ { url => abs_url($URL, '/inc_counter'),
		     on_response => sub { inc_counter(); [] } } ];

    $WEBTEST->run_tests($tests2, $OPTS);
    ok(counter() == 2);
}

# 7: test response parameter which returns some test results
{
    my $tests = [ { url => abs_url($URL, '/inc_counter'),
		    on_response => [ 'yes', 'Test 1' ] },
		  { url => abs_url($URL, '/inc_counter'),
		    on_response => [ 'no', 'Test 2' ] },
		  { url => abs_url($URL, '/inc_counter'),
		    on_response => [ 'yes', 'Test 3',
				     'no', 'Test 4' ] },
		  { url =>  abs_url($URL, '/inc_counter'),
		    on_response => [] } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => { plugins => [ '::Hooks' ] },
		  check_file => 't/test.out/on_response');
}


# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

# remove counter file
unlink $COUNTER_FILE;

# sets counter to zero
sub init_counter {
    write_file($COUNTER_FILE, 0);
}

# increase counter
sub inc_counter {
    my $counter = counter();
    $counter ++;
    write_file($COUNTER_FILE, $counter);
}

# get counter
sub counter {
    return read_file($COUNTER_FILE, 1) || 0;
}

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    my $path = $request->url->path;

    if($path eq '/inc_counter' ) {
	# count requests
	inc_counter();

	$connect->send_file_response('t/test1.txt');
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
