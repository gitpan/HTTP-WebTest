#!/usr/bin/perl -w

# $Id: 01-api.t,v 1.1.2.16 2001/11/24 16:00:54 ilya Exp $

# This script tests public API of HTTP::WebTest.

use strict;
use HTTP::Status;
use Test;

use HTTP::WebTest;

require 't/config.pl';
require 't/utils.pl';

use vars qw($HOSTNAME $PORT $URL);

BEGIN { plan tests => 15 }

# init test
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;

# 1: get default user agent object
{
    ok(defined $WEBTEST->user_agent->can('request'));
}

# 2: set our user agent
{
    my $user_agent = new LWP::UserAgent;
    $WEBTEST->user_agent($user_agent);
    ok($WEBTEST->user_agent eq $user_agent);
}

# 3: reset to default user agent
{
    $WEBTEST->user_agent(undef);
    ok(defined $WEBTEST->user_agent->can('request'));
}

# 4: check what returns method tests (should be reference on empty array)
{
    my $aref = $WEBTEST->tests;
    ok(@$aref == 0);
}

# 5-6: run single test and check last response and last request
{
    my $url = abs_url($URL, '/test-file1');
    my $test = { url => $url };
    $WEBTEST->run_test($test);
    my $request = $WEBTEST->last_request;
    my $response = $WEBTEST->last_response;
    ok($request->uri eq $url);
    ok($response->is_success);
}

# 7: run several tests
{
    my $tests = [ { url => abs_url($URL, '/test-file1') },
		  { url => abs_url($URL, '/status-forbidden') },
		  { url => abs_url($URL, '/doesnt-exist') } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/status');
}

# 8: check what returns method tests now
{
    my $aref = $WEBTEST->tests;
    ok(@$aref == 3);
}

# 9: test validate_test
{
    my $tests = [ { url => [] },
		  { url => 'http://test.org',
		    method => 'invalid' },
		  { method => 'GET' },
		  { method => 'post' },
		  { auth => [1, 2] },
		  { pauth => {} },
		  { auth => [3] },
		  { params => { a => 'b' } },
		  { params => 1 },
		  { ignore_case => '' },
		  { ignore_case => 'Yes' },
		  { ignore_case => 'nO' } ];

    my $res = '';
    for my $test (@$tests) {
	my %checks = $WEBTEST->validate_test($test);

	while(my($param, $result) = each %checks) {
	    $res .= "$param\n";
	    $res .= "Comment: " . $result->comment . "\n";
	    $res .= "Ok: " . ($result->ok ? 'yes' : 'no') . "\n";
	}

	$res .= "\n";
    }

    compare_output(output_ref => \$res,
		   check_file => 't/test.out/check-params');
}

# 10: check how webtest handlers broken tests
{
    my $tests = [ { url => [] } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/broken-test');
}

# 11-12: parse wt script
{
    my $data = read_file('t/simple.wt');

    my ($tests, $opts) = $WEBTEST->parse($data);
    ok($tests->[0]{name} eq 'Some name here');
    ok($opts->{text_require}[0] eq 'Require some');
}

# 13: run tests defined in wt script
{
    generate_wscript(file => 't/real.wt', server_url => $URL);

    my $output = '';

    $WEBTEST->run_wtscript('t/real.wt', { output_ref => \$output });

    canonical_output(server_url => $URL, output_ref => \$output);
    compare_output(output_ref => \$output,
		   check_file => 't/test.out/run-wtscript');
}

# 14-15: test num_fail and num_succeed
{
    my $tests = [ { url => abs_url($URL, '/test-file1') },
		  { url => abs_url($URL, '/status-forbidden') },
		  { url => abs_url($URL, '/doesnt-exist') } ];

    my $output = '';

    $WEBTEST->run_tests($tests, { output_ref => \$output });
    ok($WEBTEST->num_fail == 2);
    ok($WEBTEST->num_succeed == 1);
}

# try to stop server even we have been crashed
END { stop_webserver($PID) if defined $PID }

# here we handle connects to our mini web server
sub server_sub {
    my %param = @_;

    my $request = $param{request};
    my $connect = $param{connect};

    my $path = $request->url->path;

    if($path eq '/test-file1' ) {
	$connect->send_file_response('t/test1.txt');
    } elsif($path eq '/status-forbidden') {
	$connect->send_error(RC_FORBIDDEN);
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
