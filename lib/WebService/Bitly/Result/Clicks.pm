package WebService::Bitly::Result::Clicks;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_clicks) = @_;

    my $self = $class->SUPER::new($result_clicks);

    my $clicks_list;

    for my $clicks (@{ $self->data->{clicks} }) {
        push @$clicks_list, WebService::Bitly::Entry->new($clicks);
    }
    $self->{clicks_list} = $clicks_list;

    return $self;
}

sub clicks_list {
    return @{shift->{clicks_list}};
}

1;
