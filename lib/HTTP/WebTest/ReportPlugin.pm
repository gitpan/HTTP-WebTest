# $Id: ReportPlugin.pm,v 1.1.1.1 2002/01/24 12:26:28 m_ilya Exp $

package HTTP::WebTest::ReportPlugin;

=head1 NAME

HTTP::WebTest::ReportPlugin - Base class for HTTP::WebTest report plugins.

=head1 SYNOPSIS

Not applicable.

=head1 DESCRIPTION

This is subclass of
L<HTTP::WebTest|HTTP::WebTest::Plugin>. L<HTTP::WebTest|HTTP::WebTest>
report plugin classes can subclass this class. It handles some test
parameters common to report plugins by providing implementation of
method C<print>. See below.

=cut

use strict;

use Net::SMTP;

use HTTP::WebTest::Utils qw(make_access_method);

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 output_ref

I<GLOBAL PARAMETER>

A reference on scalar which accumulates text of test report. If this
test parameter is specified then value of test parameter C<fh_out> is
ignore.

This parameter can be used only when passing the test parameters
as arguments from a calling Perl script.

=head2 fh_out

I<GLOBAL PARAMETER>

A filehandle (or anything else that supports C<print>) to use for test
report output. This parameter is ignored if test parameter
C<output_ref> is specified also.

This parameter can be used only when passing the test parameters
as arguments from a calling Perl script.

=head2 mail_addresses

I<GLOBAL PARAMETER>

A list of e-mail addresses where report will be send (if sending
report is enabled with C<mail> test parameter).

=head2 mail

I<GLOBAL PARAMETER>

Option to e-mail output to one or more addresses specified by
C<mail_addresses> test parameter.

=over 4

=item * all

Send e-mail containing test results.

=item * errors

Send e-mail only if one or more tests fails.

=item * no

Do not send e-mail.

=head3 Default value

C<no>

=back

=head2 mail_server

I<GLOBAL PARAMETER>

Fully-qualified name of of the mail server (e.g., mailhost.mycompany.com).

=head3 Default value

C<localhost>

=head2 mail_from

I<GLOBAL PARAMETER>

Sets From: header for test report e-mails.

=head3 Default Value

Name of user under which test script runs.

=cut

# declare some supported test params
sub param_types {
    return { qw(output_ref     stringref
                fh_out         anything
                mail_addresses list
                mail           string
                mail_server    string
                mail_from      string) };
}

=head1 CLASS METHODS

=cut

=head2 test_output ()

=head3 Returns

Returns a reference to buffer which stores copy of test output.

=cut

*test_output = make_access_method('TEST_OUTPUT', sub { my $s = ''; \$s } );

=head2 print (@array)

Prints data in <@array> either into string (if test parameter
C<output_ref> is set) or to some filehandle (if test parameter C<fh_out>
is set) or to standard output.

Also stores this data into buffer accessible via method C<test_output>.

=cut

sub print {
    my $self = shift;

    my $output_ref = $self->global_test_param('output_ref');
    my $fh_out     = $self->global_test_param('fh_out');

    my $text = join '', @_;

    ${$self->test_output} .= $text;

    if(defined $output_ref) {
	${$output_ref} .= $text;
    } elsif(defined $fh_out) {
	print $fh_out $text;
    } else {
	print $text;
    }
}

=head2 start_tests ()

This method is called by L<HTTP::WebTest|HTTP::WebTest> at the begin
of test run. Its implementation in this class inits output buffer for
test report.

If you redefine this method in subclass be sure to call
it in new method:

    sub start_tests {
        my $self = shift;

        $self->SUPER::start_tests;

        # your code here
        ....
    }

=cut

sub start_tests {
    my $self = shift;

    # reset temporary output storage
    $self->test_output(undef);
}

=head2 end_tests ()

This method is called by L<HTTP::WebTest|HTTP::WebTest> at the end of
test run. Its implementation in this class can email test report
according test parameters C<mail***>.

If you redefine this method in subclass be sure to call
it in new method:

    sub end_tests {
        my $self = shift;

        # your code here
        ....

        $self->SUPER::end_tests;
    }

=cut

sub end_tests {
    my $self = shift;

    my $mail_addresses = $self->global_test_param('mail_addresses');
    my $mail           = $self->global_test_param('mail');
    my $mail_server    = $self->global_test_param('mail_server');
    my $mail_from      = $self->global_test_param('mail_from');

    my $num_fail = $self->webtest->num_fail;

    # check if we need to mail report
    return unless $mail;
    return unless $mail eq 'all' or $mail eq 'errors';
    return if $mail eq 'errors' and $num_fail == 0;

    # mail report
    my $smtp = Net::SMTP->new($mail_server || 'localhost');
    die "HTTP::WebTest: Can't create Net::SMTP object"
	unless defined $smtp;
    my $from = $mail_from || getlogin() || getpwuid($<) || 'nobody';
    my $to = join ', ', @$mail_addresses;
    $self->_smtp_cmd($smtp, 'mail', $from);
    $self->_smtp_cmd($smtp, 'to', $to);
    $self->_smtp_cmd($smtp, 'data');
    $self->_smtp_cmd($smtp, 'datasend', "From: $from\n");
    $self->_smtp_cmd($smtp, 'datasend', "To: $to\n");
    if ($num_fail > 0) {
	$self->_smtp_cmd($smtp, 'datasend',
			 "Subject: WEB TESTS FAILED! " .
			 "FOUND $num_fail ERROR(S)\n");
    } else {
	$self->_smtp_cmd($smtp, 'datasend',
			 "Subject: Web tests succeeded\n");
    }
    $self->_smtp_cmd($smtp, 'datasend', "\n");
    $self->_smtp_cmd($smtp, 'datasend', ${$self->test_output});
    $self->_smtp_cmd($smtp, 'dataend');
    $self->_smtp_cmd($smtp, 'quit');
}

# simple helper method which automates error handling
sub _smtp_cmd {
    my $self = shift;
    my $smtp = shift;
    my $cmd = shift;

    my $ret = $smtp->$cmd(@_);

    unless($ret) {
	my $msg = $smtp->message;
	die "HTTP::WebTest: mail error for command $cmd: $msg";
    }
}

=head1 COPYRIGHT

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

=cut

1;
