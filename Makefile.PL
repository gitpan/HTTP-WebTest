# $Id: Makefile.PL,v 1.1.1.1.2.32 2002/01/05 23:59:20 ilya Exp $

use 5.005;

use strict;

use ExtUtils::MakeMaker;
use Data::Dumper;
use File::Spec;

my %CONFIG = ();

# list of programs we install
my @PROGRAMS = qw(wt);
# what do we need to delete on realclean?
my $REALCLEAN = '.config';
# list of authors
my $AUTHOR = 'Richard Anderson <Richard.Anderson@unixscripts.com>, ' .
             'Ilya Martynov <ilya@martynov.org>';

WriteMakefile( NAME         => 'HTTP::WebTest',
	       VERSION_FROM => 'lib/HTTP/WebTest.pm',
	       PREREQ_PM    => { 'Algorithm::Diff' => 0,
				 'CGI::Cookie'     => 0,
				 'File::Temp'      => 0,
				 'HTTP::Cookies'   => 0,
				 'HTTP::Daemon'    => 0,
				 'HTTP::Request'   => 0,
				 'HTTP::Status'    => 0,
				 'LWP::UserAgent'  => 0,
				 'MIME::Base64'    => 0,
				 'Net::SMTP'       => 0,
				 'Pod::Usage'      => 0,
				 'Time::HiRes'     => 0,
				 'URI'             => 0 },
	       realclean    => { FILES => $REALCLEAN },
	       PL_FILES     => { map +("bin/$_.PL" => "bin/$_"), @PROGRAMS },
	       EXE_FILES    => [ map {"bin/$_"} @PROGRAMS ],
	       AUTHOR       => $AUTHOR,
	       ABSTRACT     => 'Run tests on remote URLs or local web files');

sub MY::manifypods {
    my $self = shift;

    my $make = $self->MY::SUPER::manifypods;

    # use PODs from INST_LIB for man page creation
    $make =~ s/(\s)lib/$1\$(INST_LIB)/g;

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
    $make .= <<MAKE;

pure_all :: pod_merge
\t\$(NOOP)

pod_merge: pm_to_blib
\t\$(PERL) pod_merge.PL lib \$(INST_LIB)
\t\@\$(TOUCH) \$\@

clean ::
\t\$(RM_F) pod_merge
MAKE

    # add README generation target
    $make .= <<MAKE;

README: $webtest_pm
\t\$(PERL) make_readme.PL $webtest_pm README

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
not have Apache you can skip this tests.

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
