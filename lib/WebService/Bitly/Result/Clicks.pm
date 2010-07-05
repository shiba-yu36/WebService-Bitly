package WebService::Bitly::Result::Clicks;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_clicks) = @_;

    my $self = $class->SUPER::new($result_clicks);

    my $results;

    for my $clicks (@{ $self->data->{clicks} }) {
        push @$results, WebService::Bitly::Entry->new($clicks);
    }
    $self->{results} = $results;

    return $self;
}

sub results {
    return @{shift->{results}};
}

1;
