# $Id: Hooks.pm,v 1.9 2002/06/21 06:48:16 richardanderson Exp $

package HTTP::WebTest::Plugin::Hooks;

=head1 NAME

HTTP::WebTest::Plugin::Hooks - Provides callbacks called during test run

=head1 SYNOPSIS

    plugins = ( ::Hooks )

    test_name = Name1
        ....
        # do some test initialization
        on_request = { My::init() }
    end_test

    test_name = Name2
        ....
        # define custom test
        on_response = ( { My::test() ? 'yes' : 'no' } => 'My test' )
    end_test

    test_name = Name3
        ....
        # call finalization code with returning any test results
        on_response = { My::finalize(); return [] }
    end_test

=head1 DESCRIPTION

This plugin module adds test parameters whose values are evaluated at
specific times of the L<HTTP::WebTest|HTTP::WebTest> test run.  It can be
used to do some initialization before doing test request, to do some
finalization when test response is received or to implement user
defined tests without writing a new plugin module.

=cut

use strict;
use URI;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy opt_params

=head2 on_request

The value of this test parameter is ignored.  However, it is evaluted
before the HTTP request is done, so it can be used to do 
initalization before the request.

=head2 on_response

This is a list parameter which is treated as test result.  It is
evaluted when the HTTP response for the test request is received.

It can be used to define custom tests without writing new plugins.
It can also be used to run some code when the HTTP response for the test
request is received.

=head3 Allowed values

    ( YESNO1, COMMENT1
      YESNO2, COMMENT2
      ....
      YESNON, COMMENTN )

Here C<YESNO>, C<COMMENT> is a test result.  C<YESNO> is either
C<yes> if test is successful or C<no> if it is not.  C<COMMENT> is a
comment associated with this test.

=head3 Example

See example in L<HTTP::WebTest::Cookbook|HTTP::WebTest::Cookbook>.

=cut

sub param_types {
    return q(on_request  anything
 	     on_response test_results);
}

# implements check for parameter type 'test_results'
sub check_test_results {
    my $self = shift;
    my $param = shift;
    my $value = shift;
    my @spec = @_;

    # first of all check if it is a list
    $self->check_list($param, $value);

    # check if it has even number of elements
    unless(@$value % 2 == 0) {
	die "HTTP::WebTest: parameter '$param' is not a list with even number of elements";
    }

    for my $i (0 .. @$value / 2 - 1) {
	my ($ok, $comment) = @$value[2 * $i, 2 * $i + 1];
	$self->validate_value("$param\[$i]", $ok, 'yesno');
	$self->validate_value("$param\[" . ($i + 1) . "]", $ok, 'scalar');
    }
}

sub prepare_request {
    my $self = shift;

    # this both checks and evaluates test parameter
    $self->validate_params(qw(on_request));
}

sub check_response {
    my $self = shift;

    $self->validate_params(qw(on_response));

    my $results = $self->test_param('on_response');

    if(defined $results) {
	my @results = ();
	for my $i (0 .. @$results / 2 - 1) {
	    my ($ok, $comment) = @$results[2 * $i, 2 * $i + 1];
	    push @results, $self->test_result($ok =~ /yes/i ? 1 : 0, $comment);
	}

	return ['User defined tests', @results] if @results;
    }

    return [];
}

=head1 COPYRIGHT

Copyright (c) 2001-2002 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
