package WebService::Bitly::ResultShorten;

use warnings;
use strict;
use Carp;

use base qw(Class::Accessor::Lvalue::Fast);

__PACKAGE__->mk_accessors(qw(
    shorten_url
    long_url
    is_new
    global_hash
    hash
    status_code
    status_text
));

sub new {
    my ($class, $result_shorten) = @_;
    my $self = bless {
        shorten_url => $result_shorten->{data}->{url},
        long_url    => $result_shorten->{data}->{long_url},
        is_new      => $result_shorten->{data}->{new_hash},
        global_hash => $result_shorten->{data}->{global_hash},
        hash        => $result_shorten->{data}->{hash},
        status_code => $result_shorten->{status_code},
        status_text => $result_shorten->{status_text},
    }, $class;
}

sub is_error {
    my $self = shift;

    return $self->status_code ne '200';
}

1;
