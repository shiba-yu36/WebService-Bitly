package WebService::Bitly::Result::Lookup;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_lookup) = @_;

    my $self = $class->SUPER::new($result_lookup);

    my $lookup_list;

    for my $lookup (@{ $self->data->{lookup} }) {
        push @$lookup_list, WebService::Bitly::Entry->new($lookup);
    }
    $self->{lookup_list} = $lookup_list;

    return $self;
}

sub lookup_list {
    return @{shift->{lookup_list}};
}

1;
