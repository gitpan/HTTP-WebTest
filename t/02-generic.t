#!/usr/bin/perl -w

# $Id: 02-generic.t,v 1.1.2.4 2001/11/20 01:34:44 ilya Exp $

# This script tests generic test types of HTTP::WebTest.

use strict;
use CGI::Cookie;
use HTTP::Response;
use HTTP::Status;
use Test;

use HTTP::WebTest;

require 't/config.pl';
require 't/utils.pl';

use vars qw($HOSTNAME $PORT $URL);

BEGIN { plan tests => 13 }

# init tests
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;

# 1: run status tests
{
    my $tests = [ { url => abs_url($URL, '/test-file1') },
		  { url => abs_url($URL, '/status-forbidden') },
		  { url => abs_url($URL, '/doesnt-exist') } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/status');
}

# 2-4: run text require tests
{
    my $tests = [ { url => abs_url($URL, '/test-file1'),
		    text_forbid => [ '123456',
				     'test test' ] },
		  { url => abs_url($URL, '/test-file1'),
		    text_require => [ '987654',
				      'failed test' ] },
		  { url => abs_url($URL, '/test-file1'),
		    regex_forbid => [ qr/\d{400}/,
				      '\s1\s2\s3\s\w{20}',
				      'abcde',
				      'failed\s\w\w\w\w'] },
		  { url => abs_url($URL, '/test-file1'),
		    regex_require => [ qr/\w+/,
				       '\s\d{3}\s',
				       qr/(?:\w\d){10,}/ ] }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/text_match1');

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => { ignore_case => 'no' },
		  check_file => 't/test.out/text_match1');

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  opts => { ignore_case => 'yes' },
		  check_file => 't/test.out/text_match2');
}

# 5: run content size checks
{
    my $tests = [ { url => abs_url($URL, '/test-file1'),
		    min_bytes => 10,
		    max_bytes => 100 },
		  { url => abs_url($URL, '/test-file2'),
		    min_bytes => 10,
		    max_bytes => 100 },
		  { url => abs_url($URL, '/test-file1'),
		    min_bytes => 100,
		    max_bytes => 50000 },
		  { url => abs_url($URL, '/test-file2'),
		    min_bytes => 100,
		    max_bytes => 50000 }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/size');
}

# 6: run tests for various HTTP methods and request params
{
    my $tests = [ { url => abs_url($URL, '/show-request'),
		    text_require => [ 'Method: <GET>',
				      'Query: <>',
				      'Content: <>'] },
                  { url => abs_url($URL, '/show-request'),
		    method => 'get',
		    text_require => [ 'Method: <GET>',
				      'Query: <>',
				      'Content: <>'] },
                  { url => abs_url($URL, '/show-request'),
		    method => 'post',
		    text_require => [ 'Method: <POST>',
				      'Query: <>',
				      'Content: <>'] },
                  { url => abs_url($URL, '/show-request'),
		    params => [ a => 'b', c => 'd', e => 'f' ],
		    text_require => [ 'Method: <GET>',
				      'Query: <a=b&c=d&e=f>',
				      'Content: <>'] },
                  { url => abs_url($URL, '/show-request'),
		    method => 'post',
		    params => [ a => 'b', c => 'd', e => 'f' ],
		    text_require => [ 'Method: <POST>',
				      'Query: <>',
				      'Content: <a=b&c=d&e=f>'] },
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/request');
}

# 7: run response time tests
{
    if(defined $ENV{TEST_FAST}) {
	skip('skip: long response time tests are disabled', 1);
    } else {
	my $tests = [ { url => abs_url($URL, '/sleep-2'),
			min_rtime => 1,
			max_rtime => 3 },
		      { url => abs_url($URL, '/sleep-4'),
			min_rtime => 1,
			max_rtime => 3 },
		      { url => abs_url($URL, '/sleep-2'),
			min_rtime => 3,
			max_rtime => 6 },
		      { url => abs_url($URL, '/sleep-4'),
			min_rtime => 3,
			max_rtime => 6 }
		    ];

	my $out_filter = sub {
	    $_[0] =~ s|( Response \s+ time \s+ \( \s+ )
                       ( \d+ \. ) ( \d+ )
                       ( \s+ \) )
                      |"$1$2" . ('0' x length($3)) . "$4"|xge;
	};

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      tests => $tests,
		      check_file => 't/test.out/time',
		      out_filter => $out_filter);
    }
}

# 8: test 'test_name' param
{
    my $tests = [ { test_name => 'Test File #1',
		    url => abs_url($URL, '/test-file1') },
		  { test_name => 'Test File #2',
		    url => abs_url($URL, '/test-file2') }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/test_name');
}

# 9: test cookies - accept-cookies, send-cookies params
{
    my $skip = $HOSTNAME !~ /\..*\./ ?
	       'skip: cannot test cookies - ' .
	       'hostname does not contain two dots' :
	       undef;
    if($skip) {
	skip($skip, 1);
    } else {
	my $tests = [ { url => abs_url($URL, '/set-cookie-c1-v1') },
		      { url => abs_url($URL, '/show-cookies'),
			text_require => [ '<c1>=<v1>' ] },
		      { url => abs_url($URL, '/set-cookie-c2-v2'),
			accept_cookies => 'no' },
		      { url => abs_url($URL, '/show-cookies'),
			text_forbid => [ '<c2>=<v2>' ] },
		      { url => abs_url($URL, '/set-cookie-c3-v3'),
			accept_cookies => 'yes' },
		      { url => abs_url($URL, '/show-cookies'),
			text_require => [ '<c3>=<v3>' ] },
		      { url => abs_url($URL, '/show-cookies'),
			send_cookies => 'no',
			text_forbid => [ '<c1>=<v1>',
					 '<c3>=<v3>'] },
		      { url => abs_url($URL, '/show-cookies'),
			send_cookies => 'yes',
			text_require => [ '<c1>=<v1>',
					  '<c3>=<v3>'] },
		    ];

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      tests => $tests,
		      check_file => 't/test.out/cookie1');
    }
}

# 10: test cookies - cookies param
{
    my $skip = $HOSTNAME !~ /\..*\./ ?
	       'skip: cannot test cookies - ' .
	       'hostname does not contain two dots' :
	       undef;
    if($skip) {
	skip($skip, 1);
    } else {
	my $tests = [ { url => abs_url($URL, '/show-cookies'),
			cookies => [ [ 0, 'c4', 'v4', '/', $HOSTNAME ],
				     [ 0, 'c5', 'v5', '/', $HOSTNAME,
				       '', '', '', '', '' ],
				     [ 0, 'c6', 'v6', '/', $HOSTNAME,
				       undef, undef, undef, undef, undef ],
				     [ 0, 'c7', 'v7', '/', $HOSTNAME,
				       '', '', '', '', '',
				       'attr1', 'avalue1' ] ],
			text_require => [ '<c4>=<v4>',
					  '<c5>=<v5>',
					  '<c6>=<v6>',
					  '<c7>=<v7>' ] },
	              { url => abs_url($URL, '/show-cookies'),
			cookies => [ [ 0, 'c8', 'v8',
				       '/wrong-path', $HOSTNAME ],
				     [ 0, 'c9', 'v9', '/',
				       'wrong.hostname.com' ] ],
			text_forbid => [ '<c8>=<v8>',
					 '<c9>=<v9>' ] }
		    ];

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      tests => $tests,
		      check_file => 't/test.out/cookie2');
    }
}

# 11: and another cookie test (tests alias parameter)
{
    my $skip = $HOSTNAME !~ /\..*\./ ?
	       'skip: cannot test cookies - ' .
	       'hostname does not contain two dots' :
	       undef;
    if($skip) {
	skip($skip, 1);
    } else {
	my $domain = $HOSTNAME;
	$domain =~ s/^.*\././;
	my $tests = [ { url => abs_url($URL, '/show-cookies'),
			cookie => [ 0,
				    'webtest',
				    'This is the cookie value',
				    '/',
				    $domain,
				    '',
				    0,
				    '',
				    2592000,
				    '',
				    'Comment',
				    'What a tasty cookie!' ],
			text_require => [ '<webtest>=<This is the cookie value>' ] }
		    ];

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      tests => $tests,
		      check_file => 't/test.out/cookie3',
		      opts => { show_html => 'yes' });
    }
}

# 12: authorization tests
{
    my $tests = [ { url => abs_url($URL, '/auth-test-user-passwd') },
		  { url => abs_url($URL, '/auth-test-user-passwd'),
		    auth => [ 'user', 'wrong-passwd' ] },
		  { url => abs_url($URL, '/auth-test-user-passwd'),
		    auth => [ 'wrong-user', 'passwd' ] },
		  { url => abs_url($URL, '/auth-test-user-passwd'),
		    auth => [ 'user', 'passwd' ] }
		];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/auth');
}

# 13: be more forgiving about short urls
{
    my $url = abs_url($URL, '/test-file1');
    $url =~ s|http://||;

    my $tests = [ { url => $url } ];

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  tests => $tests,
		  check_file => 't/test.out/short-url');
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
    } elsif($path eq '/test-file2' ) {
	$connect->send_file_response('t/test2.txt');
    } elsif($path eq '/status-forbidden') {
	$connect->send_error(RC_FORBIDDEN);
    } elsif($path eq '/show-request') {
	my $content = '';
	$content .= 'Method: <' . $request->method . ">\n";
	$content .= 'Query: <' . ($request->url->query || '') . ">\n";
	$content .= 'Content: <' . $request->content . ">\n";

	# create response object
	my $response = new HTTP::Response(RC_OK);
	$response->header(Content_Type => 'text/plain');
	$response->content($content);

	# send it to browser
	$connect->send_response($response);
    } elsif($path =~ m|^/sleep-(\d+(?:\.\d+)?)$|) {
	my $sleep = $1;
	sleep($sleep);
	$connect->send_file_response('t/test1.txt');
    } elsif($path =~ m|^/set-cookie-(\w+)-(\w+)$| ) {
	my $name = $1;
	my $value = $2;

	# create cookie
	my $cookie = new CGI::Cookie(-name => $name,
				     -value => $value,
				     -path => '/',
				     -expires => '+1M' );

	# create response object
	my $response = new HTTP::Response(RC_OK);
	$response->header(Content_Type => 'text/plain');
	$response->header(Set_Cookie => $cookie->as_string);
	$response->content('Set cookie test');

	# send it to browser
	$connect->send_response($response);
    } elsif($path eq '/show-cookies') {
	my $content = '';

	# find all cookies in headers
	for my $cookie_list ($request->header('Cookie')) {
	    for my $cookie (split /;\s*/, $cookie_list) {
		my($name, $value) = split /=/, $cookie;
		$content .= "<$name>=<$value>\n";
	    }
	}

	# create response object
	my $response = new HTTP::Response(RC_OK);
	$response->header(Content_Type => 'text/plain');
	$response->content($content);

	# send it to browser
	$connect->send_response($response);
    } elsif($path =~ m|/auth-(\w+)-(\w+)-(\w+)|) {
	my $realm = $1;
	my $user = $2;
	my $password = $3;

	# check if we have good credentials
	my $credentials = $request->header('Authorization');
	my($user1, $password1) = parse_basic_credentials($credentials);
	if(defined($user1) and defined($password1) and
	   $user eq $user1 and $password eq $password1) {
	    # authorization is ok
	    $connect->send_file_response('t/test1.txt');
	} else {
	    # authorization is either missing or wrong

	    # create response object
	    my $response = new HTTP::Response(RC_UNAUTHORIZED);
	    $response->header(WWW_Authenticate => "Basic realm=\"$realm\"");

	    # send it to browser
	    $connect->send_response($response);
	}
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
