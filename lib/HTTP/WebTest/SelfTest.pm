# $Id: SelfTest.pm,v 1.7 2003/03/02 11:52:10 m_ilya Exp $

package HTTP::WebTest::SelfTest;

=head1 NAME

HTTP::WebTest::SelfTest - Helper package for HTTP::WebTest test suite

=head1 SYNOPSIS

    use HTTP::WebTest::SelfTest;

=head1 DESCRIPTION

This module provides helper routines used by L<HTTP::WebTest> self
test suite. Plugin writers may find this module useful for
implementation of test suites for their plugins.

=cut

use strict;

use base qw(Exporter);

=head1 GLOBAL VARIABLES

This module imports in namespace of test script following global
variables.

=cut

use vars qw(@EXPORT $HOSTNAME $PORT $URL);

@EXPORT = qw($HOSTNAME $PORT $URL
             abs_url
             check_webtest
             read_file write_file
             generate_testfile canonical_output compare_output
             parse_basic_credentials
             start_webserver stop_webserver);

use Algorithm::Diff qw(diff);
use MIME::Base64;
use Sys::Hostname;
use URI;

use HTTP::WebTest::Utils qw(find_port start_webserver stop_webserver);

=head2 $HOSTNAME

The hostname of the test webserver.

=cut

$HOSTNAME = $ENV{TEST_HOSTNAME} || hostname;

=head2 $PORT

The port of the test webserver.

=cut

$PORT = find_port();
die "Can't find free port" unless defined $PORT;

=head2 $URL

The URL of the test webserer.

=cut

$URL = "http://$HOSTNAME:$PORT/";

=head1 SUBROUTINES

This module imports in namespace of test script following helper
subroutines.

=head2 abs_url($base, $rel)

=head3 Return

Returns absolute URL based on pair of base and relative URLs.

=cut

sub abs_url {
    my $abs = shift;
    my $rel = shift;

    return URI->new_abs($rel, $abs);
}

=head2 read_file($filename, $ignore_errors)

Reads a file.

=head3 Parameters

=over 4

=item $filename

Name of the file.

=item $ignore_errors

(Optional) If true then open file errors are ignored, otherwise they
raise an exception. If omit defaults to true.

=back

=head3 Returns

Whole content of the file as a string.

=cut

sub read_file {
    my $filename = shift;
    my $ignore_errors = shift;

    local *FILE;
    if(open FILE, "< $filename") {
	my $data = join '', <FILE>;
	close FILE;

	return $data;
    } else {
	die "Can't open file '$filename': $!" unless $ignore_errors;
    }

    return '';
}

=head2 write_file($filename, $data)

Writes into a file.

=head3 Parameters

=over 4

=item $filename

Name of the file.

=item $data

Data to write into the file.

=back

=cut

sub write_file {
    my $file = shift;
    my $data = shift;

    local *FILE;
    open FILE, "> $file" or die "Can't open file '$file': $!";
    print FILE $data;
    close FILE;
}

=head2 check_webtest(%params)

Runs a test sequence and compares output with a reference file.

=head3 Parameters

=over 4

=item webtest => $webtest

L<HTTP::WebTest> object to be used for running the test sequence.

=item tests => $tests

The test sequence.

=item tests => $opts

The global parameters for the test sequence.

=item out_filter => $out_filter

=back

=cut

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

=head2 generate_testfile(%params)

Generates test file from template file. I.e. it replaces substring
'<<SERVER_URL>>' with value of named parameter C<server_url>.

=head3 Parameters

=over 4

=item file => $file

Filename of test file. Template file is expected to be in file named
"$file.in".

=item server_url => $server_url

Test webserver URL.

=back

=cut

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

=head2 canonical_output(%params)

Some substrings in test output are unique for each test run. This
subroutine "fixes" test output so it becomes repeatable (unless tests
get broken).

=head3 Parameters

=over 4

=item output_ref => $output_ref

A reference on scalar which contains test output as whole string.

=item out_filter => $out_filter

An optional reference on subroutine which can be used as additional
filter. It gets passed test output as its first parameter.

=item server_url => $server_url

Test webserver URL. Normally it is unique for each test run so it gets
replaced with C<http://http.web.test/>.

=item server_hostname => $server_hostname

Test webserver URL. Normally it is unique for each machine where test
is run so it gets replaced with C<http.web.test>.

=back

=cut

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

=head2 compare_output(%params)

Tests if a test output matches content of specified reference file. If
environment variable C<TEST_FIX> is set then the test is always
succeed and the content of the reference file is overwritten with
current test output.

=head3 Parameters

=over 4

=item output_ref => $output_ref

A reference on scalar which contains test output as whole string.

=item check_file => $check_file

Filename of the reference file.

=back

=cut

sub compare_output {
    my %param = @_;

    my $check_file = $param{check_file};
    my $output2 = ${$param{output_ref}};

    my $output1 = read_file($check_file, 1);
    _print_diff($output1, $output2);
    _ok(($output1 eq $output2) or defined $ENV{TEST_FIX});

    if(defined $ENV{TEST_FIX} and $output1 ne $output2) {
	# special mode for writting test report output files

	write_file($check_file, $output2);
    }
}

# ok compatible with Test and Test::Builder
sub _ok {
    # if Test is already loaded use its ok
    if(Test->can('ok')) {
        @_ = $_[0];
        goto \&Test::ok;
    } else {
        require Test::Builder;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        Test::Builder->new->ok(@_);
    }
}

# print diff of outputs
sub _print_diff {
    my $output1 = shift;
    my $output2 = shift;

    my @diff = diff([split /\n/, $output1], [split /\n/, $output2]);

    for my $hunk (@diff) {
	for my $diff_str (@$hunk) {
	    printf "%s %03d %s\n", @$diff_str;
	}
    }
}

=head2 parse_basic_credentials($credentials)

Decodes credentials for Basic authorization scheme according RFC2617.

=head3 Returns

Returns user/password pair.

=cut

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

=head1 DEPRECATED SUBROUTINES

This module imports in namespace of test script following helper
subroutines but they are deprecated and may be removed in the future
from this module.

=head2 start_webserver

This subroutine was moved into
L<HTTP::WebTest::Utils|HTTP::WebTest::Utils> but for backward
compatibility purposes can be exported from this module.

=head2 stop_webserver

This subroutine was moved into
L<HTTP::WebTest::Utils|HTTP::WebTest::Utils> but for backward
compatibility purposes can be exported from this module.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
