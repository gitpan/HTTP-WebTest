# $Id: API.pm,v 1.9 2002/03/24 11:01:36 m_ilya Exp $

# note that it is not package HTTP::WebTest::API. That's right
package HTTP::WebTest;

=head1 NAME

HTTP::WebTest::API - API of HTTP::WebTest

=head1 SYNOPSIS

    use HTTP::WebTest;

    my $webtest = new HTTP::WebTest;

    # run test from file
    $webtest->run_wtscript('script.wt');

    # or (to pass test parameters as method arguments)
    $webtest->run_tests($tests);

See below for all API.

=head1 DESCRIPTION

This document describes Perl API of C<HTTP::WebTest>.

=head1 METHODS

=cut

use 5.005;
use strict;

use HTTP::Request;
use IO::File;
use LWP::UserAgent;
use Time::HiRes qw(time);

use HTTP::WebTest::Cookies;
use HTTP::WebTest::Utils qw(make_access_method load_package);
use HTTP::WebTest::Plugin;
use HTTP::WebTest::Test;

# BACKWARD COMPATIBILITY BITS - exported sub is from 1.xx API

use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(run_web_test);

=head2 new ()

Constructor.

=head3 Returns

A new C<HTTP::WebTest> object.

=cut

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    return $self;
}

=head2 run_tests ($tests, $optional_params)

Runs a test sequence.

=head3 Parameters

=over 4

=item * $test

A reference on array which contains test objects.

=item * $optional_params

A reference on hash which contains optional global parameters for test.

=back

=cut

sub run_tests {
    my $self = shift;
    my $tests = shift;
    my $params = shift || {};

    $self->reset_plugins;

    # reset last test object
    $self->last_test(undef);

    # convert tests to canonic representation
    my @tests = $self->convert_tests(@$tests);

    $self->tests([ @tests ]);
    $self->_global_test_params($params);

    # start tests hook
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('start_tests')) {
	    $plugin->start_tests;
	}
    }

    # run all tests
    for my $i (0 .. @{$self->tests} - 1) {
	my $test = $self->tests->[$i];
	$self->last_test_num($i);
	$self->run_test($test, $self->_global_test_params);
    }

    # reset last test object
    $self->last_test(undef);

    # end tests hook
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('end_tests')) {
	    $plugin->end_tests;
	}
    }
}

=head2 run_wtscript ($file, $optional_params)

Reads wtscript and runs tests it defines.

=head3 Parameters

=over 4

=item * $file

A filename of wtscript file.

=item * $optional_params

=back

A reference on hash which contains optional test parameters which can
override parameters defined in wtscript.

=cut

sub run_wtscript {
    my $self = shift;
    my $file = shift;
    my $opts_override = shift || {};

    my $fh = new IO::File;
    $fh->open("< $file") or
	die "HTTP::WebTest: Can't open file $file: $!";

    my $data = join '', <$fh>;
    $fh->close;

    my ($tests, $opts) = $self->parse($data);

    $self->run_tests($tests, { %$opts, %$opts_override });
}

=head2 num_fail ()

=head3 Returns

The number of failed tests.

=cut

sub num_fail {
    my $self = shift;

    my $fail = 0;

    for my $test (@{$self->tests}) {
	my $results = $test->results;

	for my $result (@$results) {
	    for my $subresult (@$result[1 .. @$result - 1]) {
		$fail ++ unless $subresult;
	    }
	}
    }

    return $fail;
}

=head2 num_succeed ()

=head3 Returns

The number of passed tests.

=cut

sub num_succeed {
    my $self = shift;

    my $succeed = 0;

    for my $test (@{$self->tests}) {
	my $results = $test->results;

	for my $result (@$results) {
	    for my $subresult (@$result[1 .. @$result - 1]) {
		$succeed ++ if $subresult;
	    }
	}
    }

    return $succeed;
}

=head2 have_succeed ()

=head3 Returns

True if all tests have passed, false otherwise.

=cut

sub have_succeed {
    my $self = shift;

    $self->num_fail > 0 ? 0 : 1;
}

=head2 parse ($data)

Parses test specification in wtscript format.

=head3 Parameters

=over 4

=item * $data

Scalar which contains test specification in wtscript format.

=back

=head3 Returns

A list of two elements. First element is a reference on array which
contains test objects. Second element is a reference on hash which
contains optional global parameters for test.

It can be passed directly to C<run_tests>.

=head3 Example

    $webtest->run_tests($webtest->parse($data));

=cut

sub parse {
    my $self = shift;
    my $data = shift;

    # load parsing module on demand - it is quite heavy
    load_package('HTTP::WebTest::Parser');
    my ($tests, $opts) = HTTP::WebTest::Parser->parse($data);

    return ($tests, $opts);
}

=head1 LOW-LEVEL API METHODS

Most users don't need to use this part of C<HTTP::WebTest> API
directly. It could be useful for users who want to:

=over 4

=item *

Write an C<HTTP::WebTest> plugin.

=item *

Get access to L<LWP::UserAgent|LWP::UserAgent>,
L<HTTP::Request|HTTP::Request>, L<HTTP::Response|HTTP::Response> and
other objects used by C<HTTP::WebTest> during runing test sequence.

=back

=head2 tests ()

=head3 Returns

A reference on array which contains test objects.

=cut

*tests = make_access_method('TESTS', sub { [] });

=head2 user_agent ($optional_user_agent)

Can switch user agent used by C<HTTP::WebTest> object if
C<$optional_user_agent> is a user agent object. If
$optional_user_agent is passed as undef, the HTTP::WebTest object is
reset to use default user agent.

=head3 Returns

An user agent object used by C<HTTP::WebTest> object.

=cut

*user_agent = make_access_method('USER_AGENT', 'create_user_agent');

=head2 plugins ($optional_plugins)

Can set plugins to be used during tests if C<$optional_plugins> is a
reference on array which contains plugin objects. If it is passed as
undef resets C<HTTP::WebTest> object to use default set of plugins.

=head3 Returns

A reference on array which contains plugin objects. Note that if you
add or remove plugin objects to this array it will change set of
plugins used by C<HTTP::WebTest> object during tests.

=cut

*plugins = make_access_method('PLUGINS', 'default_plugins');

=head2 create_user_agent ()

=head3 Returns

A new L<LWP::UserAgent> object initialized with default settings.

=cut

sub create_user_agent {
    my $self = shift;

    # create user agent
    my $user_agent = new LWP::UserAgent;

    # create cookie jar
    $user_agent->cookie_jar(new HTTP::WebTest::Cookies);

    # allow redirects after POST
    push @{ $user_agent->requests_redirectable }, 'POST';

    return $user_agent;
}

=head2 reset_user_agent ()

Resets user agent to default.

=cut

sub reset_user_agent {
    my $self = shift;

    $self->user_agent(undef);
}

=head2 reset_plugins ()

Resets set of plugin objects to default.

=cut

sub reset_plugins {
    my $self = shift;

    $self->plugins(undef);
}

=head2 default_plugins ()

=head3 Returns

A reference on set of default plugin objects.

=cut

sub default_plugins {
    my $self = shift;

    my @plugins = ();

    for my $sn_package (qw(Loader
                           SetRequest Cookies Apache
                           StatusTest TextMatchTest
                           ContentSizeTest ResponseTimeTest
                           DefaultReport)) {
	my $package = "HTTP::WebTest::Plugin::$sn_package";

	load_package($package);

	push @plugins, $package->new($self);
    }

    return [@plugins];
}

# accessor method for global test parameters data
*_global_test_params = make_access_method('GLOBAL_TEST_PARAMS');

=head2 global_test_param ($param)

=head3 Returns

A value of global test sequence parameter C<$param>.

=cut

sub global_test_param {
    my $self = shift;
    my $param = shift;

    return $self->_global_test_params->{$param};
}

=head2 last_test_num ()

=head3 Returns

A number of last test being or been run.

=cut

*last_test_num = make_access_method('LAST_TEST_NUM');

=head2 last_test ()

=head3 Returns

A <HTTP::WebTest::Test|HTTP::WebTest::Test> object which corresponds
to last test being or been run.

=cut

*last_test = make_access_method('LAST_TEST');

=head2 last_request ()

=head3 Returns

A <HTTP::Request|HTTP::Request> object used in last test.

=cut

sub last_request { shift->last_test->request(@_) }

=head2 last_response ()

=head3 Returns

A <HTTP::Response|HTTP::Response> object used in last test.

=cut

sub last_response { shift->last_test->response(@_) }

=head2 last_response_time ()

=head3 Returns

A response time for last request.

=cut

sub last_response_time { shift->last_test->response_time(@_) }

=head2 last_results ()

=head3 Returns

A reference on array which contains results of checks made by plugins
for last test.

=cut

sub last_results { shift->last_test->results(@_) }

=head2 run_test ($test, $optional_params)

Runs single test.

=head3 Parameters

=over 4

=item * $test

A test object.

=item * $optional_params

A reference on hash which contains optional global parameters for test.

=back

=cut

sub run_test {
    my $self = shift;
    my $test = shift;
    my $params = shift || {};

    # convert test to canonic representation
    $test = $self->convert_tests($test);
    $self->last_test($test);

    $self->_global_test_params($params);

    # create request (note that actual uri is more likely to be
    # set in plugins)
    my $request = HTTP::Request->new('GET' => 'http://MISSING_HOSTNAME/');
    $self->last_request($request);

    # set request object with plugins
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('prepare_request')) {
	    $plugin->prepare_request;
	}
    }

    # check if one of plugins did change request uri
    if($request->uri eq 'http://MISSING_HOSTNAME/') {
	die "HTTP::WebTest: request uri is not set";
    }

    # measure current time
    my $time1 = time;

    # get response
    my $response = $self->user_agent->request($request);
    $self->last_response($response);

    # measure current time
    my $time2 = time;

    # calculate response time
    $self->last_response_time($time2 - $time1);

    # init results
    my @results = ();

    # check response with plugins
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('check_response')) {
	    push @results, $plugin->check_response;
	}
    }

    $self->last_results(\@results);

    # report test results
    for my $plugin (@{$self->plugins}) {
	if($plugin->can('report_test')) {
	    $plugin->report_test;
	}
    }
}

=head2 convert_tests (@tests)

Converts test objects C<@tests> of any supported type to internal
canonical representation (i.e. to
L<HTTP::WebTest::Test|HTTP::WebTest::Test> objects).

=head3 Returns

A list of L<HTTP::WebTest::Test|HTTP::WebTest::Test> objects in list
context or first value from list of
L<HTTP::WebTest::Test|HTTP::WebTest::Test> object in scalar context.

=cut

sub convert_tests {
    my $self = shift;
    my @tests = @_;

    my @conv = map HTTP::WebTest::Test->convert($_), @tests;

    return wantarray ? @conv : $conv[0];
}

=head1 BACKWARD COMPATIBILITY

C<HTTP::WebTest 2.xx> offers more rich API than its predecessor
C<HTTP::WebTest 1.xx>. However while old API is deprecated it is still
supported.

It is not recommended to use it in new applications.

=cut

=head2 web_test ($file, $num_fail_ref, $num_succeed_ref, $optional_options)

Reads wtscript and runs tests it defines.

In C<HTTP::WebTest 2.xx> you should use method C<run_wtscript>.

=head3 Parameters

=over 4

=item * $file

A filename of wtscript file.

=item * $num_fail_ref

A reference on scalar where a number of failed tests will be stored or
C<undef> if you don't need it.

=item * $num_succed_ref

A reference on scalar where a number of passed tests will be stored or
C<undef> if you don't need it.

=item * $optional_params

A reference on hash which contains optional test parameters which can
override parameters defined in wtscript.

=back

=cut

sub web_test {
    my $self = shift;
    my $file = shift;
    my $num_fail_ref = shift;
    my $num_succeed_ref = shift;
    my $opts = shift || {};

    $self->run_wtscript($file, $opts);

    $$num_fail_ref = $self->num_fail if defined $num_fail_ref;
    $$num_succeed_ref = $self->num_succeed if defined $num_succeed_ref;

    return $self->have_succeed;
}

=head2 run_web_test ($tests, $num_fail_ref, $num_succeed_ref, $optional_options)

This is not a method. It is subroutine which creates a
C<HTTP::WebTest> object and runs test sequence using it.

You need either import C<run_web_test> into you namespace with

    use HTTP::WebTest qw(run_web_test);

or use full name C<HTTP::WebTest::run_web_test>

In C<HTTP::WebTest 2.xx> you should use method C<run_tests>.

=head3 Parameters

=over 4

=item * $tests

A reference on array which contains a set of test objects.

=item * $num_fail_ref

A reference on scalar where a number of failed tests will be stored or
C<undef> if you don't need it.

=item * $num_succed_ref

A reference on scalar where a number of passed tests will be stored or
C<undef> if you don't need it.

=item * $optional_params

A reference on hash which contains optional test parameters.

=back

=cut

sub run_web_test {
    my $tests = shift;
    my $num_fail_ref = shift;
    my $num_succeed_ref = shift;
    my $opts = shift || {};

    my $webtest = new HTTP::WebTest;

    $webtest->run_tests($tests, $opts);

    $$num_fail_ref = $webtest->num_fail if defined $num_fail_ref;
    $$num_succeed_ref = $webtest->num_succeed if defined $num_succeed_ref;

    return $webtest->have_succeed;
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson. All rights reserved.

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::Cookbook|HTTP::WebTest::Cookbook>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

L<LWP::UserAgent|LWP::UserAgent>

L<HTTP::Request|HTTP::Request>

L<HTTP::Response|HTTP::Response>

L<HTTP::WebTest::Cookies|HTTP::WebTest::Cookies>

L<HTTP::WebTest::Parser|HTTP::WebTest::Parser>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Test|HTTP::WebTest::Test>

=cut

1;
