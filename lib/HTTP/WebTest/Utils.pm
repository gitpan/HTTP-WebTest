# $Id: Utils.pm,v 1.1.2.13 2002/01/15 17:16:08 ilya Exp $

package HTTP::WebTest::Utils;

=head1 NAME

HTTP::WebTest::Utils - Some misc staff used by various parts of HTTP::WebTest

=head1 SYNOPSIS

    use HTTP::WebTest::Utils;
    use HTTP::WebTest::Utils qw(make_access_method find_port);
    use HTTP::WebTest::Utils qw(copy_dir load_package);

    *method = make_access_method($field);
    *method = make_access_method($field, $default_value);
    *method = make_access_method($field, sub { ... });

    find_port(hostname => $hostname);

    copy_dir($src_dir, $dst_dir);

    load_package($package);

=head1 DESCRIPTION

This packages contains some subroutines used by various parts of
L<HTTP::WebTest|HTTP::WebTest> which don't fit any its classes.

=head1 SUBROUTINES

=cut

use strict;

use Cwd;
use File::Copy;
use File::Find;
use File::Path;
use File::Spec::Functions;
use HTTP::Daemon;

use base qw(Exporter);

use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(make_access_method find_port copy_dir load_package);

=head2 make_access_method($field, $optional_default_value)

Creates anonymouse subroutine which can be used as accessor
method. Such method can be used together with objects which are based
on blessed hashes.

Typical usage is

    *method = make_access_method($field, ...);

=head3 Parameters

=over 4

=item * $field

A hash field used for created accessor method.

=item * $optional_default_value

If C<$optional_default_value> is a code reference uses values returned
by its execution as default for created accessor method. Otherwise
uses C<$optional_default_value> as name of method which returns
default value for created accessor method.

=back

=head3 Returns

=cut

sub make_access_method {
    # field name
    my $field = shift;
    # subroutine or method which returns some default value for field
    my $default_value = shift;

    my $sub = sub {
	my $self = shift;

	if(@_) {
	    $self->{$field} = shift;
	}

	unless(defined $self->{$field}) {
	    if(defined $default_value) {
		if(ref($default_value) eq 'CODE') {
		    $self->{$field} = $default_value->($self);
		} else {
		    $self->{$field} = $self->$default_value();
		}
	    }
	}

	return $self->{$field};
    };
}

=head2 find_port (hostname => $hostname)

=head3 Returns

Free port number for network interface specified by C<$hostname>.

=cut

sub find_port {
    my %param = @_;

    my $hostname = $param{hostname};

    my $daemon =
	    HTTP::Daemon->new(($hostname ? (LocalAddr => $hostname) : ()));

    if(defined $daemon) {
	my $port = $daemon->sockport;
	$daemon->close;
	return $port;
    }

    return undef;
}

=head2 copy_dir ($src_dir, $dst_dir)

Copies directiory recursively.

=cut

sub copy_dir {
    my $src_dir = shift;
    my $dst_dir = shift;

    my $cwd = getcwd;

    $dst_dir = catdir($cwd, $dst_dir)
	unless file_name_is_absolute($dst_dir);

    # define subroutine that copies files to destination directory
    # directory
    my $copytree = sub {
	my $filename = $_;

	my $rel_dirname = $File::Find::dir;

	if(-d $filename) {
	    # create this directory in destination directory tree
	    my $path = catdir($dst_dir, $rel_dirname, $filename);
	    mkpath($path) unless -d $path;
	}

	if(-f $filename) {
	    # copy this file to destination directory tree, create
	    # subdirectory if neccessary
	    my $path = catdir($dst_dir, $rel_dirname);
	    mkpath($path) unless -d $path;

	    copy($filename, catfile($path, $filename))
		or die "HTTP::WebTest: Can't copy file: $!";
	}
    };

    # descend recursively from directory, copy files to destination
    # directory
    chdir $src_dir
	or die "HTTP::WebTest: Can't chdir to directory '$src_dir': $!";
    find($copytree, '.');
    chdir $cwd
	or die "HTTP::WebTest: Can't chdir to directory '$cwd': $!";
}

=head2 load_package ($package)

Loads package unless it is already loaded.

=cut

sub load_package {
    my $package = shift;

    # check if package is loaded already (we are asuming that all of
    # them have method 'new')
    return if $package->can('new');

    eval "require $package";

    die $@ if $@;
}

=head1 COPYRIGHT

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

=cut

1;
