# these bits are from libwww
use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
    if ($Config{'osname'} eq 'VMS' or
	$Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w

!GROK!THIS!

print OUT <<'!NO!SUBS!';
# $Id: wt.PL,v 1.1.2.7 2002/01/06 01:47:19 ilya Exp $

=head1 NAME

wt - test one or more web pages, either remotely or locally

=head1 SYNOPSIS

wt [options] [WTSCRIPT ...]

 Options:
   -?, --help        brief help message
       --man         full documentation
   -V, --version     version number

=head1 OPTIONS

=over 4

=item B<-?>

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<-V>

=item B<--version>

Prints version number of L<HTTP::WebTest|HTTP::WebTest> and exits.

=back

=head1 DESCRIPTION

This program runs tests using Perl module
L<HTTP::WebTest|HTTP::WebTest> on remote URLs or local web files
containing Perl/JSP/HTML/JavaScript/etc. and generates a detailed test
report.

See docs mentioned in section L<SEE ALSO|SEE ALSO> for full
documentation.

=head1 EXIT STATUS

=over 4

=item * 0

All tests ran successfully.

=item * 1

One or more tests failed, there was an error in the input
parameter file, or there was a system runtime error.

=back

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson. All rights reserved.

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::Reference|HTTP::WebTest::Reference>

=cut

use strict;

use Pod::Usage;
use Getopt::Long;
use HTTP::WebTest 1.96;

use sigtrap qw(die normal-signals);

my $VERSION = 1.00;

my $man = 0;
my $help = 0;
my $version = 0;
GetOptions('help|?'    => \$help,
           'version|V' => \$version,
           'man'       => \$man) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
if($version) {
    my $version = HTTP::WebTest->VERSION;
    print <<TEXT;
wt version $VERSION. This program uses version $version of HTTP::WebTest.

Copyright (c) 2000-2001 Richard Anderson. All rights reserved.
Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.
TEXT
    exit 0;
}

pod2usage(1) if @ARGV < 1;

my $webtest = HTTP::WebTest->new();
my($return, $exit_status, $total_failed, $total_succeeded) = (0) x 4;
foreach my $file (@ARGV) {
    my($failed, $succeeded);
    $webtest->run_wtscript($file);
    $exit_status ||= 1 if not $webtest->have_succeed;
    $total_failed += $webtest->num_fail;
    $total_succeeded += $webtest->num_succeed;
}

exit $exit_status;
!NO!SUBS!
