# $Id: Makefile.PL,v 1.6 2002/05/12 14:40:37 m_ilya Exp $

use 5.005;

use strict;

use ExtUtils::MakeMaker;
use Data::Dumper;
use File::Spec;

my %CONFIG = ();

# what do we need to delete on realclean?
my $REALCLEAN = '.config';
# list of authors
my $AUTHOR = 'Richard Anderson <richard@richard-anderson.org>, ' .
             'Ilya Martynov <ilya@martynov.org>';

WriteMakefile( NAME         => 'HTTP::WebTest',
	       VERSION_FROM => 'lib/HTTP/WebTest.pm',
	       PREREQ_PM    => { 'Algorithm::Diff'   => 0,
				 'CGI::Cookie'       => 0,
				 'File::Temp'        => 0,
				 'HTTP::Daemon'      => 0,
				 'LWP'               => 5.60,
				 'MIME::Base64'      => 0,
				 'Net::SMTP'         => 0,
				 'Parse::RecDescent' => 0,
				 'Pod::Usage'        => 0,
				 'Pod::Man'          => 1.14,
				 'Time::HiRes'       => 0,
				 'URI'               => 0 },
	       realclean    => { FILES => $REALCLEAN },
	       EXE_FILES    => [ File::Spec->catfile(qw(bin wt)) ],
	       AUTHOR       => $AUTHOR,
	       ABSTRACT     => 'Run tests on remote URLs or local web files');

sub MY::dist_core {
    my $self = shift;

    my $make = $self->MY::SUPER::dist_core();

    # add our hook for dist target
    $make =~ s/^dist : /dist : distprepare /m;

    return $make;
}

sub MY::postamble {
    my $make = '';

    # verify standard input and output are attached to a terminal
    if(-t STDIN and -t STDOUT) {
	$make .= apache_dir_setup();
	$CONFIG{APACHE_EXEC} = apache_exec_setup();

	print STDOUT "\n";
    }

    write_config();

    # add pod merge target
    my $webtest_pm = File::Spec->catfile(qw(lib HTTP WebTest.pm));
    my $pod_merge_pl = File::Spec->catfile(qw(scripts pod_merge.PL));
    $make .= <<MAKE;

# we are lacking dependencies on plugin POD files yet
$webtest_pm : $webtest_pm.in $pod_merge_pl
\t\$(PERL) $pod_merge_pl lib $webtest_pm.in $webtest_pm
MAKE

    # add README generation target
    my $make_readme_pl = File::Spec->catfile(qw(scripts make_readme.PL));
    $make .= <<MAKE;

README: $webtest_pm $make_readme_pl
\t\$(PERL) $make_readme_pl $webtest_pm README
MAKE

    # add distprepare target (dist target depends on it)
    $make .= <<MAKE;

distprepare :: README
\t\$(NOOP)

distprepare :: $webtest_pm
\t\$(NOOP)
MAKE

    return $make;
}

# asks if http-webtest directory should be installed and adds to
# makefile target to install http-webtest directory if required
sub apache_dir_setup {
    my $apache_dir = undef;

    # verify that we don't run on Win32 system. Local web files
    # test mode is not supported on that platform
    if($^O ne 'MSWin32') {
	while(1) {
	    print_prompt(<<TEXT);

HTTP-WebTest requires installation of the http-webtest directory for
running local file tests. If you do not use local file tests you can
skip installation of this directory.

Install http-webtest directory? [Y/n]:
TEXT

	    my $response = <STDIN>;
	    chomp($response);
	    if($response =~ /^(?:y(?:es)?|)$/i) {
		# user asked for directory installation
		$apache_dir = '/usr/local/etc';

		print_prompt(<<TEXT);

Enter directory that will contain http-webtest directory.

Directory? [$apache_dir]:
TEXT

		my $response = <STDIN>;
		chomp($response);
		$apache_dir = $response if $response;
		last if -d $apache_dir;
		print STDOUT <<TEXT;

ERROR: $apache_dir is not a valid directory
TEXT
	    } else {
		last;
	    }
	}
    }

    my $make = defined $apache_dir ? <<TEXT : '';

pure_install ::
\t-\@\$(CP) -r http-webtest $apache_dir

TEXT

    return $make;
}

# finds where apache binary is located
sub apache_exec_setup {
    my $apache_exec = undef;

    # verify that we don't run on Win32 system. Local web files
    # test mode is not supported on that platform
    if($^O ne 'MSWin32') {
	while(1) {
	    print_prompt(<<TEXT);

HTTP-WebTest automated test suite contains tests for local web files
test mode. Running these tests requires Apache web server. If you do
not have Apache you can skip these tests.

Run local web files test mode tests during 'make test'? [Y/n]:
TEXT

	    my $response = <STDIN>;
	    chomp($response);
	    if($response =~ /^(?:y(?:es)?|)$/i) {
		# user asked to run tests
		$apache_exec = $ENV{'APACHE'} || which('apache') ||
		               which('httpd') || '/usr/lib/httpd/httpd';

		print_prompt(<<TEXT);

Please enter filename of Apache executable file.

Filename? [$apache_exec]:
TEXT

		my $response = <STDIN>;
		chomp($response);
		$apache_exec = $response if $response;
		last if -x $apache_exec;
		print STDOUT <<TEXT;

ERROR: $apache_exec is not a valid executable file
TEXT
	    } else {
		last;
	    }
	}
    }

    return $apache_exec;
}

# finds executable in PATH (code is stolen from Apache::test)
sub which {
    foreach (map { "$_/$_[0]" } split /:/, $ENV{PATH}) {
        next unless m,^/,;
        return $_ if -x;
    }
}

# dumps config params hash
sub write_config {
    local *FILE;
    open FILE, '> .config' or die "Can't write to file '.config': $!";

    print FILE Data::Dumper->Dump([\%CONFIG], [qw(*CONFIG)]);

    close FILE;
}

sub print_prompt {
    my $text = shift;
    chomp $text;
    print STDOUT $text, ' ';
}
