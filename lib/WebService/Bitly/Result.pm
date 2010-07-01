package WebService::Bitly::Result;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Result::Shorten;
use WebService::Bitly::Result::Validate;
use WebService::Bitly::Result::HTTPError;
use WebService::Bitly::Result::Expand;
use WebService::Bitly::Result::Clicks;
use WebService::Bitly::Result::BitlyProDomain;
use WebService::Bitly::Result::Lookup;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    data
    status_code
    status_txt
));

sub new {
    my ($class, $result) = @_;
    my $self = $class->SUPER::new($result);
}

sub is_error {
    my $self = shift;

    return $self->status_code >= 400;
}

1;
