# $Id: Loader.pm,v 1.1.2.5 2002/01/15 17:16:08 ilya Exp $

package HTTP::WebTest::Plugin::Loader;

=head1 NAME

HTTP::WebTest::Plugin::Loader - Loads external plugins

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin allows to load external L<HTTP::WebTest|HTTP::WebTest>
plugins.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

use HTTP::WebTest::Utils qw(load_package);

=head1 TEST PARAMETERS

=head2 plugins

A list of module names. Loads these modules and registers them as
L<HTTP::WebTest|HTTP::WebTest> plugins. If name of plugin starts with
C<::> prepends it with C<HTTP::WebTest::Plugin>. So

    plugins = ( ::ValidateHTML )

is equal to

    plugins = ( HTTP::WebTest::Plugin::ValidateHTML )

=cut

sub param_types {
    return { qw(plugins list) };
}

sub start_tests {
    my $self = shift;

    my $plugins = $self->test_param('plugins');

    for my $plugin (@$plugins) {
	my $name = $plugin;

	if($name =~ /^::/) {
	    $name = 'HTTP::WebTest::Plugin' . $name;
	}

	load_package($name);

	push @{$self->webtest->plugins}, $name->new($self->webtest);
    }
}

=head1 COPYRIGHT

Copyright (c) 2001,2002 Ilya Martynov. All rights reserved.

This module is free software.  It may be used, redistributed and/or
modified under the terms of the Perl Artistic License.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
