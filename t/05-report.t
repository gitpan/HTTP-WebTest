#!/usr/bin/perl -w

# $Id: 05-report.t,v 1.2 2002/02/12 12:47:35 m_ilya Exp $

# This script tests core plugins of HTTP::WebTest.

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

BEGIN { plan tests => 11 }

# init tests
my $PID = start_webserver(port => $PORT, server_sub => \&server_sub);
my $WEBTEST = HTTP::WebTest->new;
my $TEST = { url => abs_url($URL, '/test-file1'),
	     text_require => [ '987654' ] };
my $COOKIE_TEST = { url => abs_url($URL, '/set-cookie-c1-v1') };
my $COOKIE_FILTER = sub { $_[0] =~ s/expires=.*?GMT/expires=SOMEDAY/;};

# 1: test fh_out parameter
{
    my $temp_file = 't/report';

    my $fh = new IO::File;
    $fh->open("> $temp_file") or die "Can't open file $temp_file: $!";
    $WEBTEST->run_tests([ $TEST ], { fh_out => $fh });
    $fh->close;

    my $output = read_file($temp_file);

    canonical_output(server_url => $URL, output_ref => \$output);
    compare_output(check_file => 't/test.out/report-fh',
		   output_ref => \$output);

    unlink $temp_file;
}

# 2: test show_html parameter
{
    my $opts = { show_html => 'yes' };

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  opts => $opts,
		  tests => [ $TEST ],
		  check_file => 't/test.out/report-html');
}

# 3-4: test show_cookie parameter
{
    my $skip = $HOSTNAME !~ /\..*\./ ?
	       'skip: cannot test cookies - ' .
	       'hostname does not contain two dots' :
	       undef;
    if($skip) {
	skip($skip, 1);
	skip($skip, 1);
    } else {
	my $opts = { show_cookies => 'yes' };

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      opts => $opts,
		      out_filter => $COOKIE_FILTER,
		      tests => [ $COOKIE_TEST ],
		      check_file => 't/test.out/report-cookie1');

	# note that second time we should send cookie ourselves
	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      opts => $opts,
		      out_filter => $COOKIE_FILTER,
		      tests => [ $COOKIE_TEST ],
		      check_file => 't/test.out/report-cookie2');
    }
}

# 5: test show_cookie and show_html parameters
{
    my $skip = $HOSTNAME !~ /\..*\./ ?
	       'skip: cannot test cookies - ' .
	       'hostname does not contain two dots' :
	       undef;
    if($skip) {
	skip($skip, 1);
    } else {
	my $opts = { show_html => 'yes',
		     show_cookies => 'yes' };

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      opts => $opts,
		      out_filter => $COOKIE_FILTER,
		      tests => [ $COOKIE_TEST ],
		      check_file => 't/test.out/report-html-cookie');
    }
}

# 6-7: test terse parameter
{
    my $tests = [ $TEST,
		  { url => abs_url($URL, '/non-existent') } ];

    for my $terse (qw(summary failed_only)) {
	my $opts = { terse => $terse };

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      opts => $opts,
		      tests => $tests,
		      check_file => "t/test.out/report-terse-$terse");
    }
}

# 8-9: test default_report parameter
{
    my $tests = [ $TEST,
		  { url => abs_url($URL, '/non-existent') } ];

    for my $default_report (qw(yes no)) {
	my $opts = { default_report => $default_report };

	check_webtest(webtest => $WEBTEST,
		      server_url => $URL,
		      opts => $opts,
		      tests => $tests,
		      check_file => "t/test.out/default-report-$default_report");
    }
}

# 10: test HTTP::WebTest::Plugin::HarnessReport plugin
{
    my $tests = [ $TEST,
		  { url => abs_url($URL, '/non-existent') },
		  { test_name => 'BlaBla',
		    url => abs_url($URL, '/non-existent') },
		];

    my $opts = { plugins => [ '::HarnessReport' ],
		 default_report => 'no' };

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  opts => $opts,
		  tests => $tests,
		  check_file => 't/test.out/test-harness')
}

# 11: test show_headers parameter
{
    # remove cookies from cookie jar - it affects output of report plugin
    $WEBTEST->reset_user_agent;

    my $tests = [ $TEST,
		  { url => abs_url($URL, '/non-existent') } ];

    my $opts = { show_headers => 'yes' };

    my $out_filter = sub {
	$_[0] =~ s/: .*?GMT/: SOMEDAY/g;
	$_[0] =~ s|Server: libwww-perl-daemon/[\w\.]*|Server: libwww-perl-daemon/NN|g;
	$_[0] =~ s|User-Agent: HTTP-WebTest/[\w\.]*|User-Agent: HTTP-WebTest/NN|g;
    };

    check_webtest(webtest => $WEBTEST,
		  server_url => $URL,
		  opts => $opts,
		  out_filter => $out_filter,
		  tests => $tests,
		  check_file => 't/test.out/show-headers')
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
    } else {
	$connect->send_error(RC_NOT_FOUND);
    }
}
