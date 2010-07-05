package WebService::Bitly::Result::Info;

use warnings;
use strict;
use Carp;

use WebService::Bitly::Entry;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_info) = @_;
    my $self = $class->SUPER::new($result_info);
    my $results;

    for my $info (@{$self->data->{info}}) {
        push @$results, WebService::Bitly::Entry->new($info);
    }
    $self->{results} = $results;

    return $self;
}

sub results {
    return @{shift->{results}};
}

1;
