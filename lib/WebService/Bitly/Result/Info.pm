package WebService::Bitly::Result::Info;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_info) = @_;
    my $self = $class->SUPER::new($result_info);
    my $info_list;

    for my $info (@{$self->data->{info}}) {
        push @$info_list, WebService::Bitly::Entry->new($info);
    }
    $self->{info_list} = $info_list;

    return $self;
}

sub info_list {
    return @{shift->{info_list}};
}

1;
