# $Id: HarnessReport.pm,v 1.1.1.1 2002/01/24 12:26:30 m_ilya Exp $

package HTTP::WebTest::Plugin::HarnessReport;

=head1 NAME

HTTP::WebTest::Plugin::HarnessReport - Test::Harness compatible reports

=head1 SYNOPSIS

    plugins = ::HarnessReport
    default_report = no

=head1 DESCRIPTION

This plugin creates L<Test::Harness|Test::Harness> compatible test
reports. This plugin is not loaded by default by
L<HTTP::WebTest|HTTP::WebTest>. To load it use global test parameter
C<plugins>.

Unless you want to get mix of outputs from default and this report
plugins default report plugin should disabled. See parameter
C<default_report> (value C<no>).

Test parameters C<plugins> and C<default_report> are documented in
L<HTTP::WebTest|HTTP::WebTest>.

=cut

use strict;

use base qw(HTTP::WebTest::ReportPlugin);
use HTTP::WebTest::Utils qw(make_access_method);

=head1 TEST PARAMETERS

None.

=cut

sub start_tests {
    my $self = shift;

    $self->SUPER::start_tests;

    my $test_num = @{$self->webtest->tests};

    $self->print(1, '..', $test_num, "\n");
}

sub report_test {
    my $self = shift;

    my @results = @{$self->webtest->last_test->results};

    my $test_name = $self->test_param('test_name');
    my $url = 'N/A';
    if($self->webtest->last_request) {
	$url = $self->webtest->last_request->uri;
    }

    $self->print("\n");
    $self->print("# URL: $url\n");
    $self->print("# Test Name: $test_name\n") if defined $test_name;

    my $all_ok = 1;

    for my $result (@{$self->webtest->last_results}) {
	# test results
	my $group_comment = $$result[0];

	my @results = @$result[1 .. @$result - 1];

	$self->print("# ",  uc($group_comment), "\n");

	for my $subresult (@$result[1 .. @$result - 1]) {
	    my $comment = $subresult->comment;
	    my $ok      = $subresult->ok ? 'SUCCEED' : 'FAIL';
	    $all_ok   &&= $ok;

	    $self->print("#   $comment: $ok\n");
	}
    }

    $self->print(($all_ok ? 'ok' : 'not ok'), "\n");
}

=head1 COPYRIGHT

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::ReportPlugin|HTTP::WebTest::ReportPlugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
