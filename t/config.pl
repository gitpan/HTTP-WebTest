#!/usr/bin/perl -w

# $Id: config.pl,v 1.1.2.7 2001/08/11 23:00:36 ilya Exp $

# Here we set some global vars for test scripts

use strict;
use Sys::Hostname;

use HTTP::WebTest::Utils qw(find_port);

use vars qw(%CONFIG $HOSTNAME $PORT $URL $APACHE_EXEC);

read_config();

# hostname of test webserver
$HOSTNAME = $ENV{TEST_HOSTNAME} || hostname;
# port for test webserver
$PORT = find_port(hostname => $HOSTNAME);
die "Can't find free port" unless defined $PORT;
# url of test webserver
$URL = "http://$HOSTNAME:$PORT/";
# filename of apache executable file
$APACHE_EXEC = $CONFIG{APACHE_EXEC};

sub read_config {
    unless(defined do '.config') {
	if($!) {
	    die "Can't read file '.config': $!";
	} else {
	    die $@;
	}
    }
}

1;
