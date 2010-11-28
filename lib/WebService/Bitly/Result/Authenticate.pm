package WebService::Bitly::Result::Authenticate;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_authenticate) = @_;
    my $self = $class->SUPER::new($result_authenticate);
}

sub user_name {
    return shift->data->{authenticate}->{username};
}

sub api_key {
    return shift->data->{authenticate}->{api_key};
}

sub is_success {
    my $self = shift;
    return 0 if $self->is_error;
    return $self->data->{authenticate}->{successful} ? 1 : 0;
}

1;
