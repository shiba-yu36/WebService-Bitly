package WebService::Bitly::Entry;

use warnings;
use strict;
use Carp;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    short_url
    global_hash
    long_url
    user_hash
));

sub new {
    my ($class, $entry) = @_;
    my $self = $class->SUPER::new($entry);
}

1;
