package WebService::Bitly::Result::Expand;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_expand) = @_;
    my $self = $class->SUPER::new($result_expand);
    my $results;

    for my $expand (@{$self->data->{expand}}) {
        push @$results, WebService::Bitly::Entry->new($expand);
    }
    $self->{results} = $results;

    return $self;
}

sub results {
    return @{shift->{results}};
}

1;
