# $Id: Plugin.pm,v 1.1.2.31 2002/01/13 02:47:58 ilya Exp $

package HTTP::WebTest::Plugin;

=head1 NAME

HTTP::WebTest::Plugin - Base class for HTTP::WebTest plugins.

=head1 SYNOPSIS

Not applicable.

=head1 DESCRIPTION

L<HTTP::WebTest|HTTP::WebTest> plugin classes can subclass this
class. It provides some useful helper methods.

=head1 METHODS

=cut

use strict;

use HTTP::WebTest::TestResult;
use HTTP::WebTest::Utils qw(make_access_method);

=head2 new ($webtest)

Constructor.

=head3 Returns

A new plugin object which will be used by
L<HTTP::WebTest|HTTP::WebTest> object C<$webtest>.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    my $webtest = shift;

    $self->webtest($webtest);

    return $self;
};

=head2 webtest

=head3 Returns

A L<HTTP::WebTest|HTTP::WebTest> object which uses this plugin.

=cut

*webtest = make_access_method('WEBTEST');

=head2 test_param ($param, $default)

=head3 Returns

If latest test parameter C<$param> is not defined returns
C<$optional_default> or false if it is not defined.

If latest test parameter C<$param> is defined returns it's value.

=cut

sub test_param {
    my $self = shift;
    my $param = shift;
    my $default = shift;

    my $global_value = $self->webtest->global_test_param($param);

    my $value;
    if(defined $self->webtest->last_test) {
	$value = $self->webtest->last_test->param($param);
	$value = $self->merge_param($value, $global_value);
    } else {
	$value = $global_value;
    }

    return $default unless defined $value;
    return $value;
}

=head2 yesno_test_param ($param, $optional_default)

=head3 Returns

If latest test parameter C<$param> is not defined returns
C<$optional_default> or false if it is not defined.

If latest test parameter C<$param> is defined returns true if latest
test parameter C<$param> is C<yes>. False otherwise.

=cut

sub yesno_test_param {
    my $self = shift;
    my $param = shift;
    my $default = shift || 0;

    my $value = $self->test_param($param);

    return $default unless defined $value;
    return $value =~ /^yes$/i;
}

=head2 merge_params ($param, $value, $global_value)

Merges test parameter value with global test parameter value.

=head3 Returns

A merged test parameter value.

=cut

sub merge_param {
    my $self = shift;
    my $value = shift;
    my $global_value = shift;

    return defined $value ? $value : $global_value;
}

=head2 test_result ($ok, $comment)

Factory method which creates test result object.

=head3 Returns

A L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult> object.

=cut

sub test_result {
    my $self = shift;
    my $ok = shift;
    my $comment = shift;

    my $result = HTTP::WebTest::TestResult->new;
    $result->ok($ok);
    $result->comment($comment);

    return $result;
}

=head2 validate_test ($test)

Checks test parameters.

=head3 Returns

An array of L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult> objects.

=cut

sub validate_test {
    my $self = shift;
    my $test = shift;

    my %param_types = %{$self->param_types};

    my %checks = ();
    while(my($param, $type) = each %param_types) {
	my $method = 'check_' . $type;
	my $value = $test->param($param);
	next unless defined $value;
	my $ok = $self->$method($value);
	my $message = "Parameter $param should be of $type type.";
	$checks{$param} = $self->test_result($ok, $message);
    }

    return %checks;
}

=head2 param_types

Method which should be redefined in subclasses. Returns information
about test parameters which are supported by plugin. Used to validate
tests.

=head3 Returns

An hash reference. Keys are names of test parameters which are
supported by plugin. Values are their type.

=cut

sub param_types { {} }

=head2 check_anything ($value)

Method which checks test parameter if it is value is of C<anything>
type.

=head3 Returns

Always true.

=cut

sub check_anything { 1 }

=head2 check_list ($value)

Method which checks test parameter if it is value is of C<list>
type.

=head3 Returns

True if C<$value> is an array reference. False otherwise.

=cut

sub check_list {
    my $self = shift;
    my $value = shift;

    return ref($value) eq 'ARRAY';
}

=head2 check_string ($value)

Method which checks test parameter if it is value is of C<string>
type.

=head3 Returns

True if C<$value> is a string. False otherwise.

=cut

sub check_string {
    my $self = shift;
    my $value = shift;

    return not ref($value);
}

=head2 check_stringref ($value)

Method which checks test parameter if it is value is of C<stringref>
type.

=head3 Returns

True if C<$value> is a string reference. False otherwise.

=cut

sub check_stringref {
    my $self = shift;
    my $value = shift;

    return ref($value) eq 'SCALAR';
}

=head2 check_uri ($value)

Method which checks test parameter if it is value is of C<uri>
type.

=head3 Returns

True if C<$value> is an URI. False otherwise.

=cut

sub check_uri {
    my $self = shift;
    my $value = shift;

    my $check = $self->check_string($value);
    $check ||= (defined ref($value) and UNIVERSAL::isa($value, 'URI'));

    return $check;
}

=head2 check_hashlist ($value)

Method which checks test parameter if it is value is of C<hashlist>
type.

=head3 Returns

True if C<$value> is a hash reference or an array reference which
points to array containing even number of elements. False otherwise.

=cut

sub check_hashlist {
    my $self = shift;
    my $value = shift;

    my $check = $self->check_list($value);
    $check &&= ((@$value % 2) == 0);
    $check ||= ref($value) eq 'HASH';

    return $check;
}

=head2 check_yesno ($value)

Method which checks test parameter if it is value is of C<yesno>
type.

=head3 Returns

True if C<$value> is either C<yes> or C<no>. False otherwise.

=cut

sub check_yesno {
    my $self = shift;
    my $value = shift;

    return $value =~ /^(?:yes|no)$/i;
}

=head1 COPYRIGHT

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

L<HTTP::WebTest::ReportPlugin|HTTP::WebTest::ReportPlugin>

=cut

1;
