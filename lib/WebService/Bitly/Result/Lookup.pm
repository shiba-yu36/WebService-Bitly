package WebService::Bitly::Result::Lookup;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_lookup) = @_;

    my $self = $class->SUPER::new($result_lookup);

    my $results;

    for my $lookup (@{ $self->data->{lookup} }) {
        push @$results, WebService::Bitly::Entry->new($lookup);
    }
    $self->{results} = $results;

    return $self;
}

sub results {
    return @{shift->{results}};
}

1;
