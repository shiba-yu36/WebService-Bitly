package WebService::Bitly::Result::Expand;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_shorten) = @_;
    my $self = $class->SUPER::new($result_shorten);
}

sub expand_url {
    return shift->data->{expand}->[0]->{long_url};
}

sub short_url {
    return shift->data->{expand}->[0]->{short_url};
}

sub global_hash {
    return shift->data->{expand}->[0]->{global_hash};
}

sub user_hash {
    return shift->data->{expand}->[0]->{user_hash};
}

1;
