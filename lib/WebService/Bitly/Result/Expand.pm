package WebService::Bitly::Result::Expand;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_expand) = @_;
    my $self = $class->SUPER::new($result_expand);
    my $expand_list;

    for my $expand (@{$self->data->{expand}}) {
        push @$expand_list, WebService::Bitly::Entry->new($expand);
    }
    $self->{expand_list} = $expand_list;

    return $self;
}

sub expand_list {
    return @{shift->{expand_list}};
}

1;
