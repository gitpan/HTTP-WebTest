#!/usr/bin/perl -w

# $Id: pod_merge.PL,v 1.1.2.2 2002/01/05 23:20:07 ilya Exp $

use strict;

use File::Find;
use File::Spec;

require 't/utils.pl';

my ($sourcedir, $libdir) = @ARGV;

my $plugin_dir = File::Spec->catdir($sourcedir, qw(HTTP WebTest Plugin));

my $in_ref_file = File::Spec->catfile($sourcedir, qw(HTTP WebTest Reference.pod));
my $out_ref_file = File::Spec->catfile($libdir, qw(HTTP WebTest Reference.pod));

# get list of plugins
my @plugins = (File::Spec->catfile($sourcedir, qw(HTTP WebTest ReportPlugin.pm)));
find({ no_chdir => 1,
       wanted => sub {
	   return unless -f and /\.pm$/;
	   push @plugins, $_;
       } },
    $plugin_dir);

my $ref_data = read_file($in_ref_file);

# regexp to find TEST PARAMETERS section
my $sectionRe = qr/=head1\ TEST\ PARAMETERS # find the beging of section
                   (.*?) # content of the section
                   =cut # find the end of section
                  /sx;

# find all TEST PARAMETERS sections
my $sections = '';
for my $plugin (@plugins) {
    my $plugin_data = read_file($plugin);

    my($section) = $plugin_data =~ $sectionRe;

    next unless defined $section;

    $sections .= $section;
}

# sort content of sections
my @sections = map "=head2$_", grep /\S/, split '=head2', $sections;
@sections = map $_->[1],
            sort { $a->[0] cmp $b->[0] }
            map { my($name) = $_ =~ /=head2\s+([a-z_]+)/; [ $name => $_ ] }
            @sections;
$sections = join '', @sections;

# insert TEST PARAMETERS section
$ref_data =~ s/(=for\ pod_merge\ TEST\ PARAMETERS) # point for insertion
                /$sections$1/x;

chmod 0644, $out_ref_file or die "Can't chmod '$out_ref_file' to 644: $!";
write_file($out_ref_file, $ref_data);
chmod 0444, $out_ref_file or die "Can't chmod '$out_ref_file' to 444: $!";
