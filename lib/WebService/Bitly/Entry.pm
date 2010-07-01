package WebService::Bitly::Entry;

use warnings;
use strict;
use Carp;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    error

    short_url
    hash
    global_hash
    long_url
    user_hash

    user_clicks
    global_clicks

    url
));

sub new {
    my ($class, $entry) = @_;
    my $self = $class->SUPER::new($entry);
}

sub is_error {
    return shift->error || 0;
}

1;
