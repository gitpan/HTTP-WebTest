# $Id: Parser.pm,v 1.17 2002/06/22 20:08:38 m_ilya Exp $

package HTTP::WebTest::Parser;

=head1 NAME

HTTP::WebTest::Parser - Parse wtscript files.

=head1 SYNOPSIS

    use HTTP::WebTest::Parser;

    my $tests = HTTP::WebTest::Parser->parse($data);

=head1 DESCRIPTION

Parses a wtscript file and converts it to a set of test objects.

=head1 CLASS METHODS

=cut

use strict;

use Text::Balanced qw(extract_codeblock extract_delimited);

use HTTP::WebTest::Utils qw(eval_in_playground make_sub_in_playground);

use constant ST_FILE       => 0;
use constant ST_TEST_BLOCK => 1;

# horizontal space regexp
my $reHS = qr/[\t ]/;
# sequence of any chars which doesn't contain ')', space chars and '=>'
my $reWORD = qr/(?: (?: [^=)\s] | [^)\s] (?!>) )+ )/x;

=head2 parse ($data)

Parses wtscript text data passed in a scalar variable C<$data>.

=head3 Returns

A list of two elements - a reference to an array that contains test
objects and a reference to a hash that contains test parameters.

=cut

sub parse {
    my $class = shift;
    my $data = shift;

    my($tests, $opts) = eval { _parse($data) };

    if($@) {
	my $exc = $@;
	chomp $exc;

	my $parse_pos = pos $data;

	# find reminder of string near error (without surrounding
	# whitespace)
	$data =~ /\G $reHS* (.*?) $reHS* $/gmx;
	my $near = $1;
	if($near eq '') {
	    $near = 'at the end of line';
	} else {
	    $near = "near '$near'";
	}

	# count lines
	my $line_num = () = substr($data, 0, $parse_pos) =~ m|$|gmx;
        pos($data) = $parse_pos;
	$line_num-- if $data =~ /\G \z/gx;

	die <<MSG;
HTTP::WebTest: wtscript parsing error
Line $line_num $near: $exc
MSG
    }


    return ($tests, $opts);
}

sub _parse {
    my $state = ST_FILE;
    my $opts  = {};
    my $tests = [];
    my $test  = undef;

  PARSER:
    while(1) {
	# eat whitespace
	$_[0] =~ /\G \s+/gcx;

	if($_[0] =~ /\G \#.*/gcx) {
	    # found comment - just ignore it
	    next;
	}

	if($state == ST_FILE) {
	    if($_[0] =~ /\G \z/gcx) {
		# end of file
		last PARSER;
	    } elsif($_[0] =~ /\G test_name (?=\W)/gcx) {
		# found new test block start
		$test = {};
		$state = ST_TEST_BLOCK;

		# find test block name
		if($_[0] =~ /\G $reHS* = $reHS* (?: \n $reHS*)?/gcx) {
		    $test->{test_name} = _parse_scalar($_[0]);

		    die "Test name is missing\n"
			unless defined $test->{test_name};
		}
	    } else {
		# expect global test parameter
		my($name, $value) = _parse_param($_[0]);

		if(defined $name) {
		    _set_test_param($opts, $name, $value);
		} else {
		    die "Global test parameter or test block is expected\n";
		}
	    }
	} elsif($state == ST_TEST_BLOCK) {
	    if($_[0] =~ /\G end_test (?=\W)/gcx) {
		push @$tests, $test;
		$state = ST_FILE;
	    } else {
		# expect test parameter
		my($name, $value) = _parse_param($_[0]);

		if(defined $name) {
		    _set_test_param($test, $name, $value);
		} else {
		    die "Test parameter or end_test is expected\n";
		}
	    }
	} else {
	    die "Unknown state\n";
	}
    }

    return($tests, $opts);
}

sub _set_test_param {
    my $href  = shift;
    my $name  = shift;
    my $value = shift;

    if(exists $href->{$name}) {
	$href->{$name} = [ $href->{$name} ]
	    if ref($href->{$name}) and ref($href->{$name}) eq 'ARRAY';
	push @{$href->{$name}}, $value;
    } else {
	$href->{$name} = $value;
    }
}

sub _parse_param {
    my $name;

    if($_[0] =~ /\G ([a-zA-Z_]+)                 # param name
                 $reHS* = $reHS* (?: \n $reHS*)? # = (and optional space chars)
                /gcx) {
	$name = $1;
    } else {
	return;
    }

    my $value = _parse_value($_[0]);
    return unless defined $value;

    return ($name, $value);
}

sub _parse_value {
    if($_[0] =~ /\G \(/gcx) {
	# list elem
        #
        # ( scalar
        #   ...
        #   scalar )
        #
        # ( scalar => scalar
        #   ...
        #   scalar => scalar )

	my @list = ();

	while(1) {
	    # eat whitespace
	    $_[0] =~ /\G \s+/gcx;

	    # exit loop on closing bracket
	    last if $_[0] =~ /\G \)/gcx;

	    my $value = _parse_value($_[0]);

	    die "Missing right bracket\n"
		unless defined $value;

	    push @list, $value;

	    if($_[0] =~ /\G $reHS* => $reHS* /gcx) {
		# handles second part of scalar => scalar syntax
		my $value = _parse_value($_[0]);

		die "Missing right bracket\n"
		    unless defined $value;

		push @list, $value;
	    }
	}

	return \@list;
    } else {
	# may return undef
	return _parse_scalar($_[0]);
    }
}

sub _parse_scalar {
    my $parse_pos = pos $_[0];

    if($_[0] =~ /\G (['"])/gcx) {
	my $delim = $1;

        pos($_[0]) = $parse_pos;
	my($extracted) = extract_delimited($_[0]);
	die "Can't find string terminator \"$delim\"\n"
	    if $extracted eq '';

	if($delim eq "'" or $extracted !~ /[\$\@\%]/) {
	    # variable interpolation impossible - just evalute string
	    # to get rid of escape chars
	    my $ret = eval_in_playground($extracted);

	    chomp $@;
	    die "Eval error\n$@\n" if $@;

	    return $ret;
	} else {
	    # variable interpolation possible - evaluate as subroutine
	    # which will be used as callback
	    my $ret = make_sub_in_playground($extracted);

	    chomp $@;
	    die "Eval error\n$@\n" if $@;

	    return $ret;
	}
    } elsif($_[0] =~ /\G \{/gcx) {
        pos($_[0]) = $parse_pos;
	my($extracted) = extract_codeblock($_[0]);
	die "Missing right curly bracket\n"
	    if $extracted eq '';

	my $ret = make_sub_in_playground($extracted);

	chomp $@;
	die "Eval error\n$@\n" if $@;

	return $ret;
    } else {
	$_[0] =~ /\G ((?: $reWORD $reHS+ )* $reWORD )/gcxo;
	my $extracted = $1;

	# may return undef
	return $extracted;
    }
}

=head1 COPYRIGHT

Copyright (c) 2001-2002 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

=cut

1;
