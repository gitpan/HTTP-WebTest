# $Id: HelloWorld.pm,v 1.1.1.1 2002/01/24 12:26:18 m_ilya Exp $

package HelloWorld;

use strict;

use base qw(HTTP::WebTest::Plugin);

sub check_response {
    my $self = shift;

    my $path = $self->webtest->last_request->uri->path;

    my $ok = $path eq '/hello';

    return ['Are we welcome?', $self->test_result($ok, 'Hello, World!')];
}

1;
