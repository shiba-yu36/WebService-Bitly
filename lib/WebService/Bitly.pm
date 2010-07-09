package WebService::Bitly;

use warnings;
use strict;
use Carp;

use URI;
use URI::QueryParam;
use LWP::UserAgent;
use JSON;

use WebService::Bitly::Result::Shorten;
use WebService::Bitly::Result::Validate;
use WebService::Bitly::Result::HTTPError;
use WebService::Bitly::Result::Expand;
use WebService::Bitly::Result::Clicks;
use WebService::Bitly::Result::BitlyProDomain;
use WebService::Bitly::Result::Lookup;
use WebService::Bitly::Result::Authenticate;
use WebService::Bitly::Result::Info;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    user_name
    user_api_key
    end_user_name
    end_user_api_key
    domain
    version
    base_url
    ua
));

sub new {
    my ($class, %args) = @_;
    if (!defined $args{user_name} || !defined $args{user_api_key}) {
        carp("user_name and user_api_key are both required parameters.\n");
    }

    $args{version} = $args{version} || 'v3';
    $args{ua} = LWP::UserAgent->new(
        env_proxy => 1,
        timeout   => 30,
    );
    $args{base_url} = 'http://api.bit.ly/';

    my $self = $class->SUPER::new({%args});
}

sub shorten {
    my ($self, $url) = @_;
    if (!defined $url) {
        carp("url is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/shorten");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(x_login  => $self->end_user_name)    if $self->end_user_name;
       $api_url->query_param(x_apiKey => $self->end_user_api_key) if $self->end_user_api_key;
       $api_url->query_param(domain   => $self->domain)           if $self->domain;
       $api_url->query_param(format   => 'json');
       $api_url->query_param(longUrl  => $url);

    my $response = $self->ua->get($api_url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }
    
    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::Result::Shorten->new($bitly_response);
}

sub expand {
    my ($self, %args) = @_;
    my $short_urls = $args{short_urls} || [];
    my $hashes     = $args{hashes} || [];
    if (!$short_urls && !$hashes) {
        carp("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/expand");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(format   => 'json');
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    my $response = $self->ua->get($api_url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::Result::Expand->new($bitly_response);
}

sub validate {
    my ($self) = @_;

    my $api_url = URI->new($self->base_url . $self->version . "/validate");
       $api_url->query_param(format   => 'json');
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(x_login  => $self->end_user_name);
       $api_url->query_param(x_apiKey => $self->end_user_api_key);

    my $response = $self->ua->get($api_url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::Result::Validate->new($bitly_response);
}

sub set_end_user_info {
    my ($self, $end_user_name, $end_user_api_key) = @_;

    if (!defined $end_user_name || !defined $end_user_api_key) {
        carp("end_user_name and end_user_api_key are both required parameters.\n");
    }

    $self->end_user_name($end_user_name);
    $self->end_user_api_key($end_user_api_key);
    
    return $self;
}

sub clicks {
    my ($self, %args) = @_;
    my $short_urls   = $args{short_urls} || [];
    my $hashes       = $args{hashes} || [];
    if (!$short_urls && !$hashes) {
        carp("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/clicks");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(format   => 'json');
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    my $response = $self->ua->get($api_url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::Result::Clicks->new($bitly_response);
}

sub bitly_pro_domain {
    my ($self, $domain) = @_;
    if (!$domain) {
        carp("domain is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/bitly_pro_domain");
       $api_url->query_param(format   => 'json');
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(domain   => $domain);

    my $response = $self->ua->get($api_url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::Result::BitlyProDomain->new($bitly_response);
}

sub lookup {
    my ($self, $urls) = @_;
    if (!$urls) {
        carp("urls is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/lookup");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(format   => 'json');
       $api_url->query_param(url      => reverse(@$urls));
    
    my $response = $self->ua->get($api_url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::Result::Lookup->new($bitly_response);
}

sub authenticate {
    my ($self, $end_user_name, $end_user_password) = @_;

    my $api_url = URI->new($self->base_url . $self->version . "/authenticate");

    my $response = $self->ua->post($api_url, [
        format     => 'json',
        login      => $self->user_name,
        apiKey     => $self->user_api_key,
        x_login    => $end_user_name,
        x_password => $end_user_password,
    ]);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::Result::Autenticate->new($bitly_response);
}

sub info {
    my ($self, %args) = @_;
    my $short_urls   = $args{short_urls} || [];
    my $hashes       = $args{hashes} || [];
    if (!$short_urls && !$hashes) {
        carp("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/info");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(format   => 'json');
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    my $response = $self->ua->get($api_url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    my $bitly_response = from_json($response->{_content});
    return WebService::Bitly::Result::Info->new($bitly_response);
}

1;
