#!/usr/bin/perl -w

# $Id: 06-parser.t,v 1.2 2002/01/28 09:49:55 m_ilya Exp $

# This script tests wt scripts parser

use strict;
use IO::File;
use Test;

use HTTP::WebTest::Parser;

require 't/utils.pl';

BEGIN { plan tests => 27 }

# 1-24: check parsing wt script (contain all syntax variants)
{
    my $filename = shift;

    my $data = read_file('t/simple.wt');
    my ($tests, $opts) = HTTP::WebTest::Parser->parse($data);

    # check $tests
    ok($tests->[0]{test_name} eq 'Some name here');
    ok($tests->[0]{auth}[0] eq 'name');
    ok($tests->[0]{auth}[1] eq 'value');
    ok($tests->[0]{regex_require}[0] eq 'Quoted text " test');
    ok($tests->[0]{regex_require}[1] eq 'We can => quote \'');
    ok($tests->[0]{url} eq 'www.dot.com');
    ok($tests->[0]{regex_forbid}[0] eq 'More = tests');
    ok($tests->[0]{regex_forbid}[1] eq 'Some @#$%^&* chars');
    ok($tests->[0]{regex_forbid}[2] eq 'more');
    ok($tests->[0]{regex_forbid}[3] eq 'tests and fun');
    ok($tests->[0]{regex_forbid}[4] eq 'abcdef 1234');
    ok($tests->[0]{regex_forbid}[5] eq ' a b c d \' e f ');
    ok($tests->[1]{test_name} eq 'Another name');
    ok($tests->[1]{url} eq 'www.tiv.net');
    ok($tests->[1]{cookie}[0][0] eq '0');
    ok($tests->[1]{cookie}[0][1] eq 'webtest');
    ok($tests->[1]{cookie}[0][2] eq 'This is the cookie value');
    ok($tests->[1]{cookie}[1][1] eq 'webtest1');

    # check $opts
    ok($opts->{text_require}[0] eq 'Require some');
    ok($opts->{text_require}[1] eq 'text');
    ok($opts->{text_forbid}[0] eq 'Another');
    ok($opts->{text_forbid}[1] eq 'syntax');
    ok($opts->{text_forbid}[2] eq 'for list');
    ok($opts->{text_forbid}[3] eq 'elements');
}

# 25-27: check error handling for borked wtscript files
parse_error_check('t/borked1.wt', 't/test.out/borked1.err');
parse_error_check('t/borked2.wt', 't/test.out/borked2.err');
parse_error_check('t/borked3.wt', 't/test.out/borked3.err');

sub parse_error_check {
    my $wtscript = shift;
    my $check_file = shift;

    eval {
	my $data = read_file($wtscript);
	my ($tests, $opts) = HTTP::WebTest::Parser->parse($data);
    };
    if($@) {
	my $text = $@;
	compare_output(check_file => $check_file, output_ref => \$text);
    } else {
	ok(0);
    }
}
