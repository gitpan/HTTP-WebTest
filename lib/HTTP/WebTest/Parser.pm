# $Id: Parser.pm,v 1.1.2.8 2002/01/02 15:27:16 ilya Exp $

package HTTP::WebTest::Parser;

=head1 NAME

HTTP::WebTest::Parser - Parse wtscript files.

=head1 SYNOPSIS

    use HTTP::WebTest::Parser;

    my $tests = HTTP::WebTest::Parser->parse($data);

=head1 DESCRIPTION

Parses wtscript and converts it in set of test objects.

=head1 CLASS METHODS

=cut

use strict;

use IO::File;
use Parse::RecDescent;

# wtscript grammar
my $parser = new Parse::RecDescent (q{
    file: chunk(s) eofile { [ @{$item[1]} ] }

    chunk: comment
         | test
         | param

    comment: /#.*/ { [ 'comment', $item[1] ] }

    test: starttest testchunk(s) endtest
        { [ 'test', [ [ 'param', 'name', $item[1] ], @{$item[2]} ] ] }

    testchunk: comment | param

    starttest: 'test_name' '=' scalar { $item[3] }

    endtest: 'end_test'

    param: name '=' value { [ 'param', $item[1], $item[3] ] }

    name : /[a-zA-Z_]+/ { $item[1] eq 'test_name' ? undef : $item[1] }

    value: '(' list ')' { $item[2] }
         | scalar       { $item[1] }

    list: listelem(s) { [ map ref($_) eq 'ARRAY' ? @$_ : $_, @{$item[1]} ] }

    listelem: scalar '=>' scalar { [$item[1], $item[3]] }
            | scalar

    scalar: qscalar
          | uscalar

    qscalar: /'([^\']*)'/ { $1 }
           | /"([^\"]*)"/ { $1 }

    uscalar: <rulevar: $word_re = qr/ (?: [^=)\s] | [^)\s] (?!>) ) /x>

    uscalar: / (?: $word_re+ [ \t]+ )* $word_re+ /xo

    eofile: /^\Z/
			     });

=head2 parse ($data)

Parses wtscript passed as scalar variable C<$data>.

=head3 Returns

A list of two elements - a reference on array which contains test
objects and a reference on hash which contains test params.

=cut

sub parse {
    my $class = shift;
    my $content = shift;

    my $data = $parser->file($content);

    my @data = grep $_->[0] ne 'comment', @$data;
    my @params = grep $_->[0] eq 'param', @data;
    my @tests = grep $_->[0] eq 'test', @data;

    my %params = _conv_param->(@params);
    for my $test (@tests) {
	my @test = grep $_->[0] ne 'comment', @{$$test[1]};
	$test = { _conv_param->(@test) };
    }

    return (\@tests, \%params);
}

# converts params data derived from parser wt script into param hash
sub _conv_param {
    my @params = @_;

    my %params = ();
    my %counter = ();

    for my $param (@params) {
	my($type, $name, $value) = @$param;

	die "HTTP:::WebTest: $type is not param"
	    unless $type eq 'param';

	$counter{$name} ++;

	if($counter{$name} > 1) {
	    if($counter{$name} > 2) {
		push @{$params{$name}}, $value;
	    } else {
		$params{$name} = [ $params{$name}, $value ];
	    }
	} else {
	    $params{$name} = $value;
	}
    }

    return %params;
}

=head1 COPYRIGHT

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

=cut

1;