#!/usr/bin/perl -w

# $Id: utils.pl,v 1.4 2002/02/21 01:02:10 m_ilya Exp $

# some subs common for all tests are defined here

use strict;
use Algorithm::Diff qw(diff);
use HTTP::Daemon;
use HTTP::Status;
use MIME::Base64;
use POSIX qw(SIGTERM);
use URI;

# returns url based on absolute and relative urls
sub abs_url {
    my $abs = shift;
    my $rel = shift;

    return URI->new_abs($rel, $abs);
}

# just reads file and returns its content
sub read_file {
    my $file = shift;
    my $dont_die = shift;

    local *FILE;
    if(open FILE, "< $file") {
	my $data = join '', <FILE>;
	close FILE;

	return $data;
    } else {
	die "Can't open file '$file': $!" unless $dont_die;
    }

    return '';
}

# just writes some dat into file
sub write_file {
    my $file = shift;
    my $data = shift;

    local *FILE;
    open FILE, "> $file" or die "Can't open file '$file': $!";
    print FILE $data;
    close FILE;
}

# runs webtest and compares its output with file
sub check_webtest {
    my %param = @_;

    my $webtest = $param{webtest};
    my $tests = $param{tests};
    my $opts = $param{opts} || {};

    my $output = '';

    $webtest->run_tests($tests, { %$opts, output_ref => \$output });
    canonical_output(%param, output_ref => \$output);
    compare_output(%param, output_ref => \$output);
}

# generate test file from template
sub generate_testfile {
    my %param = @_;

    my $file = $param{file};
    my $in_file = $file . '.in';

    # prepare wt script file
    my $data = read_file($in_file);
    $data =~ s/<<SERVER_URL>>/$param{server_url}/g;

    $data = <<WARNING . $data;
# Note: $file is autogenerated from $in_file. DO NOT EDIT $file.
# Your changes will be lost. Edit $in_file instead.

WARNING

    write_file($file, $data);
}

# replaces unique susbstrings in test output
sub canonical_output {
    my %param = @_;

    my $output_ref = $param{output_ref};
    my $out_filter = $param{out_filter};
    my $server_url = $param{server_url};
    my $server_hostname = $param{server_hostname};

    # run test filter if defined
    if(defined $out_filter) {
	$out_filter->($$output_ref);
    }

    # change urls on some canonical in test output
    if(defined $server_url) {
	my $url = abs_url($server_url, '/')->as_string;
	$$output_ref =~ s|\Q$url\E
                         |http://http.web.test/|xg;
    }

    # change urls on some canonical in test output
    if(defined $server_hostname) {
	$$output_ref =~ s|http://\Q$server_hostname\E:\d+/
                         |http://http.web.test/|xg;
    }
}

sub compare_output {
    my %param = @_;

    my $check_file = $param{check_file};
    my $output2 = ${$param{output_ref}};

    my $output1 = read_file($check_file, 1);
    print_diff($output1, $output2);
    ok(($output1 eq $output2) or defined $ENV{TEST_FIX});

    if(defined $ENV{TEST_FIX} and $output1 ne $output2) {
	# special mode for writting test report output files

	write_file($check_file, $output2);
    }
}

# print diff of outputs
sub print_diff {
    my $output1 = shift;
    my $output2 = shift;

    my @diff = diff([split /\n/, $output1], [split /\n/, $output2]);

    for my $hunk (@diff) {
	for my $diff_str (@$hunk) {
	    print "@$diff_str\n";
	}
    }
}

# forks web server proccess
sub start_webserver {
    my %param = @_;

    # try to start server
    my $daemon = HTTP::Daemon->new(LocalPort => $param{port}, ReuseAddr => 1)
	or die;

    # fork server to separate process
    my $pid = fork;
    die unless defined $pid;
    return $pid if $pid != 0;

    # when we are run under debugger do not stop and call debugger at
    # the exit of the forked process. This helps to workaround problem
    # when forked process tries to takeover and to screw the terminal
    $DB::inhibit_exit = 0;

    # set 'we are working' flag
    my $done = 0;

    # close on SIGTERM
    $SIG{TERM} = sub { $done = 1 };

    # handle requests untill we are killed
    eval {
	until($done) {
	    # wait one tenth of second for connection
	    my $rbits = '';
	    vec($rbits, $daemon->fileno, 1) = 1;
	    my $nfound = select $rbits, '', '', 0.1;

	    # if we have connection then handle it
	    if($nfound > 0) {
		my $connect = $daemon->accept;
		die unless defined $connect;

		while (my $request = $connect->get_request) {
		    $param{server_sub}->(connect => $connect,
					 request => $request);
		}
		$connect->close;
		undef $connect;
	    }
	}
    };
    # in any case try to shutdown daemon correctly
    $daemon->close;
    if($@) { die $@ };

    exit 0;
}

# kills web server process
sub stop_webserver {
    my $pid = shift;

    return kill SIGTERM, $pid;
}

# decode credentials for Basic authorization scheme according RFC2617
sub parse_basic_credentials {
    my $credentials = shift;

    return () unless defined $credentials;
    $credentials =~ m|^ \s* Basic \s+ ([A-Za-z0-9+/=]+) \s* $|x;
    my $basic_credentials = $1;
    return () unless defined $basic_credentials;
    my $user_pass = decode_base64($basic_credentials);
    my($user, $password) = $user_pass =~ /^ (.*) : (.*) $/x;
    return () unless defined $password;

    return ($user, $password);
}

1;
