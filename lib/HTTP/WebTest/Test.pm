# $Id: Test.pm,v 1.1.2.9 2002/01/02 15:27:16 ilya Exp $

package HTTP::WebTest::Test;

=head1 NAME

HTTP::WebTest::Test - Test object class

=head1 SYNOPSIS

    use HTTP::WebTest::Test;

    my $test = HTTP::WebTest::Test->new(%params);
    my $test = HTTP::WebTest::Test->convert($raw_test);

    my $value = $test->param($param);

    my $results = $test->results;
    my $result = $test->result->[0];
    $test->result->[0] = $result;
    $test->results([ @results ]);


=head1 DESCRIPTION

Objects of this class represent tests. They store both test params and
test results.

=head1 CLASS METHODS

=cut

use strict;

use HTTP::WebTest::Utils qw(make_access_method);

=head2 new (%params)

Constructor.

=head3 Parameters

=over 4

=item * %params

A hash with test parameters.

=back

=head3 Returns

A new C<HTTP::WebTest::Test> object.

=cut

sub new {
    my $class = shift;
    my %params = @_;

    my $self = bless {}, $class;
    $self->_params({ %params });

    return $self;
}

# accessor method for test params data
*_params = make_access_method('PARAMS', sub { {} });

=head2 param ($param)

=head3 Returns

A value of test parameter named C<$param>.

=cut

sub param {
    my $self = shift;
    my $param = shift;

    return $self->_params->{$param};
}

=head2 results ($optional_results)

Can set L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult> objects
for this C<HTTP::WebTest::Test> object if an array reference
C<$optional_results> is passed.

=head3 Returns

A reference on array which contains
L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult> objects.

=cut

*results = make_access_method('RESULTS', sub { [] });

=head2 convert ($test)

Tries to convert test definition in some form into
C<HTTP::WebTest::Test> object. Currenlty supports test defintion in
form of C<HTTP::WebTest::Test> object (it is just passed throw) or in
form of hash reference:

    { test_param1 => test_value1, test_param2 => test_value2 }

=head3 Returns

A new C<HTTP::WebTest::Test> object.

=cut

sub convert {
    my $class = shift;
    my $test = shift;

    return $test if UNIVERSAL::isa($test, 'HTTP::WebTest::Test');

    my $conv_test = $class->new(%$test);

    return $conv_test;
}

=head1 COPYRIGHT

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult>

=cut

1;
