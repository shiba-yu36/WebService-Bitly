package WebService::Bitly;

use warnings;
use strict;
use Carp;

use URI;
use URI::QueryParam;
use LWP::UserAgent;
use JSON;
use WebService::Bitly::ResultShorten;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    user_name
    user_api_key
    end_user_name
    end_user_api_key
    domain
    base_url
));

sub new {
    my ($class, $args) = @_;
    if (!defined $args->{user_name} || !defined $args->{user_api_key}) {
        carp("user_name and user_api_key are both required parameters.\n");
    }
    
    my $self = bless {
        user_name        => $args->{user_name},
        user_api_key     => $args->{user_api_key},
        end_user_name    => $args->{end_user_name},
        end_user_api_key => $args->{end_user_api_key},
        domain           => $args->{domain},
        base_url         => 'http://api.bit.ly/',
    }, $class;
}

sub shorten {
    my ($self, $url) = @_;
    if (!defined $url) {
        carp("url is required parameter.\n");
    }
    if (!defined $self->user_name || !defined $self->user_api_key) {
        carp("user_name and user_api_key are both required. please set both.\n");
    }

    my $api_url = URI->new($self->base_url . "v3/shorten");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(x_login  => $self->end_user_name)    if $self->end_user_name;
       $api_url->query_param(x_apiKey => $self->end_user_api_key) if $self->end_user_api_key;
       $api_url->query_param(domain   => $self->domain)           if $self->domain;
       $api_url->query_param(format   => 'json');
       $api_url->query_param(longUrl  => $url);

    my $ua = LWP::UserAgent->new(
        env_proxy => 1,
        timeout => 30,
    );
    my $response = $ua->get($api_url);
    return if !$response->is_success;
    
    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::ResultShorten->new($bitly_response);
}

1;
