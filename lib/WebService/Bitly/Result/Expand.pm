package WebService::Bitly::Result::Expand;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_shorten) = @_;
    my $self = $class->SUPER::new($result_shorten);
    my $expand_lists;

    for my $expand (@{$self->data->{expand}}) {
        push @$expand_lists, WebService::Bitly::Entry->new($expand);
    }
    $self->{expand_lists} = $expand_lists;

    return $self;
}

sub expand_lists {
    return @{shift->{expand_lists}};
}

1;
