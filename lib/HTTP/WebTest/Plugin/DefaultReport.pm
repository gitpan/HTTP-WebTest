# $Id: DefaultReport.pm,v 1.1.2.33 2002/01/13 03:48:02 ilya Exp $

package HTTP::WebTest::Plugin::DefaultReport;

=head1 NAME

HTTP::WebTest::Plugin::DefaultReport - Default test report plugin.

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin is default test report plugin. Builds simple plain text
report.

=cut

use strict;

use base qw(HTTP::WebTest::ReportPlugin);
use HTTP::WebTest::Utils qw(make_access_method);

=head1 TEST PARAMETERS

=head2 test_name

Name associated with this url in the test report and error messages.

=head2 show_html

Include content of HTTP response in the test report.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 show_cookie

Option to display any cookies sent or received.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 terse

Option to display shorter test report.

=over 4

=item * summary

Only a one-line summary for each URL

=item * failed_only

Only tests that failed and the summary

=item * no

Show all tests and the summary

=head3 Default value

C<no>

=back

=cut

sub param_types {
    return { %{ shift->SUPER::param_types },
	     qw(test_name   string
                show_html   yesno
                show_cookie yesno
                terse       string) };
}

sub validate_test {
    my $self = shift;
    my $test = shift;

    my %checks = $self->SUPER::validate_test($test);

    if(exists $checks{terse}) {
	$checks{terse} &&=
	    $self->test_result($test->param('terse') =~ /^(?:no|summary|failed_only)$/i ? 1 : 0,
			       'Parameter terse can be either no, summary or failed_only.');
    }

    return %checks;
}

# accessor for temporary buffer
*tempout_ref = make_access_method('TEMPOUT_REF', sub { my $s = ''; \$s } );

sub start_tests {
    my $self = shift;

    $self->SUPER::start_tests;

    # reset temporary output storage
    $self->tempout_ref(undef);
}

sub report_test {
    my $self = shift;

    # get test params we handle
    my $test_name = $self->test_param('test_name');
    my $show_html = $self->yesno_test_param('show_html');
    my $show_cookie = $self->yesno_test_param('show_cookie');
    my $terse = lc $self->test_param('terse');

    my $url = 'N/A';
    if($self->webtest->last_request) {
	$url = $self->webtest->last_request->uri;
    }

    return if defined $terse and $terse eq 'summary';

    my $out = '';

    # test header
    $out .= "Test Name: $test_name \n"
	if defined $test_name;
    $out .= "URL: $url\n\n";

    for my $result (@{$self->webtest->last_results}) {
	# test results
	my $group_comment = $$result[0];

	my @results = @$result[1 .. @$result - 1];

	if(defined($terse) and $terse eq 'failed_only') {
	    @results = grep +(not $_->ok), @results;
	}

	next unless @results;

	$out .= $self->sformat(<<FORMAT, uc($group_comment));
  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
FORMAT

	for my $subresult (@$result[1 .. @$result - 1]) {
	    my $comment = $subresult->comment;
	    my $ok = $subresult ? 'SUCCEED' : 'FAIL';

	    $out .= $self->sformat(<<FORMAT, $comment, $ok);
    @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<
FORMAT
	}
    }

    my $response = $self->webtest->last_response;
    my $request = $self->webtest->last_request;

    if($show_cookie) {
	# sent and recieved cookies

	my @sent = $request->header('Cookie');
	my @recv = $response->header('Set-Cookie');

	$out .= "\n";

	$out .= "  SENT COOKIE(S)\n";
	for my $cookie (@sent) {
	    $out .= "    $cookie\n";
	}
	unless(@sent) {
	    $out .= "    *** none ***\n";
	}

	$out .= "  RECEIVED COOKIE(S)\n";
	for my $cookie (@recv) {
	    $out .= "    $cookie\n";
	}
	unless(@recv) {
	    $out .= "    *** none ***\n";
	}
    }

    if($show_html) {
	# content in response

	$out .= "\n";

	$out .= "  PAGE CONTENT:\n";
	$out .= $response->content . "\n";
    }

    $out .= "\n\n";

    ${$self->tempout_ref} .= $out;
}

sub end_tests {
    my $self = shift;

    $self->print("Failed  Succeeded  Test Name\n");

    my $total_fail_num = 0;
    my $total_suc_num = 0;

    for my $test (@{$self->webtest->tests}) {
	my $results = $test->results;

	my $fail_num = 0;
	my $suc_num = 0;
	for my $result (@$results) {
	    for my $subresult (@$result[1 .. @$result - 1]) {
		if($subresult) {
		    $suc_num ++;
		} else {
		    $fail_num ++;
		}
	    }
	}

	$total_fail_num += $fail_num;
	$total_suc_num += $suc_num;

	my $name = $test->param('test_name') || '*** no name ***';
	$self->fprint(<<FORMAT, $fail_num, $suc_num, $name);
 @|||||     @||||| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
FORMAT
    }

    $self->print("\n\n");

    $self->print(${$self->tempout_ref});

    $self->print("Total web tests failed: $total_fail_num ",
		 " succeeded: $total_suc_num\n");

    $self->SUPER::end_tests;
}

# formated output
sub sformat {
    my $self = shift;
    my $format = shift;
    local $^A = '';
    formline($format, @_);
    return $^A;
}

# print line using some format specification
sub fprint {
    my $self = shift;
    my $format = shift;
    $self->print($self->sformat($format, @_));
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson. All rights reserved.

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
