#!/usr/bin/perl -w

# $Id: make_readme.PL,v 1.1.1.1 2002/01/24 12:26:33 m_ilya Exp $

use strict;

use Pod::Text;

require 't/utils.pl';

my($webtest_pm, $readme) = @ARGV;

my $parser = Pod::Text->new(width => 78);

# convert POD to text
$parser->parse_from_file($webtest_pm, $readme);

my $data = read_file($readme);

# kill SYNOPSIS
$data =~ s/\nSYNOPSIS.*?DESCRIPTION/\nDESCRIPTION/s;
# kill all from Getting Started until RESTRICTIONS section
$data =~ s/\n\s*Getting Started.*?RESTRICTIONS/\n\nRESTRICTIONS/s;
# kill SEE ALSO section
$data =~ s/\nSEE ALSO.*//s;

write_file($readme, $data);
