package WebService::Bitly;

use warnings;
use strict;
use Carp;
use UNIVERSAL::require;

our $VERSION = '0.01';

use URI;
use URI::QueryParam;
use LWP::UserAgent;
use JSON;

use WebService::Bitly::Result::HTTPError;

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
        croak("user_name and user_api_key are both required parameters.\n");
    }

    $args{version} ||= 'v3';
    $args{ua} = LWP::UserAgent->new(
        env_proxy => 1,
        timeout   => 30,
    );
    $args{base_url} ||= 'http://api.bit.ly/';

    return $class->SUPER::new(\%args);
}

sub shorten {
    my ($self, $url) = @_;
    if (!defined $url) {
        croak("url is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/shorten");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(x_login  => $self->end_user_name)    if $self->end_user_name;
       $api_url->query_param(x_apiKey => $self->end_user_api_key) if $self->end_user_api_key;
       $api_url->query_param(domain   => $self->domain)           if $self->domain;
       $api_url->query_param(format   => 'json');
       $api_url->query_param(longUrl  => $url);

    $self->_do_request($api_url, 'Shorten');
}

sub expand {
    my ($self, %args) = @_;
    my $short_urls = $args{short_urls} || [];
    my $hashes     = $args{hashes} || [];
    if (!$short_urls && !$hashes) {
        croak("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/expand");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(format   => 'json');
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    $self->_do_request($api_url, 'Expand');
}

sub validate {
    my ($self) = @_;

    my $api_url = URI->new($self->base_url . $self->version . "/validate");
       $api_url->query_param(format   => 'json');
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(x_login  => $self->end_user_name);
       $api_url->query_param(x_apiKey => $self->end_user_api_key);

    $self->_do_request($api_url, 'Validate');
}

sub set_end_user_info {
    my ($self, $end_user_name, $end_user_api_key) = @_;

    if (!defined $end_user_name || !defined $end_user_api_key) {
        croak("end_user_name and end_user_api_key are both required parameters.\n");
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
        croak("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/clicks");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(format   => 'json');
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    $self->_do_request($api_url, 'Clicks');
}

sub bitly_pro_domain {
    my ($self, $domain) = @_;
    if (!$domain) {
        croak("domain is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/bitly_pro_domain");
       $api_url->query_param(format   => 'json');
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(domain   => $domain);

    $self->_do_request($api_url, 'BitlyProDomain');
}

sub lookup {
    my ($self, @urls) = @_;
    if (!@urls) {
        croak("urls is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/lookup");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(format   => 'json');
       $api_url->query_param(url      => reverse(@urls));

    $self->_do_request($api_url, 'Lookup');
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
        croak("either short_urls or hashes is required parameter.\n");
    }

    my $api_url = URI->new($self->base_url . $self->version . "/info");
       $api_url->query_param(login    => $self->user_name);
       $api_url->query_param(apiKey   => $self->user_api_key);
       $api_url->query_param(format   => 'json');
       $api_url->query_param(shortUrl => reverse(@$short_urls))   if $short_urls;
       $api_url->query_param(hash     => reverse(@$hashes))       if $hashes;

    $self->_do_request($api_url, 'Info');
}

sub _do_request {
    my ($self, $url, $result_class) = @_;

    my $response = $self->ua->get($url);

    if (!$response->is_success) {
        return WebService::Bitly::Result::HTTPError->new({
            status_code => $response->code,
            status_txt  => $response->message,
        });
    }

    $result_class = 'WebService::Bitly::Result::' . $result_class;
    $result_class->require;

    my $bitly_response = from_json($response->{_content});
    return $result_class->new($bitly_response);
}

1;

__END__;


=head1 NAME

WebService::Bitly - A Perl interface to the bit.ly API

=head1 VERSION

This document describes version 0.01 of WebService::Bitly, released *** .

=head1 SYNOPSIS

    use WebService::Bitly;

    my $bitly = WebService::Bitly->new(
        user_name => 'shibayu',
        user_api_key => 'R_1234567890abcdefg',
    );

    my $result_shorten = $bitly->shorten('http://example.com/');
    if (!$result_shorten->is_error) {
        my $short_url = $result_shorten->short_url;
    }

=head1 METHODS

=head2 new(%param)

Create a new WebService::Bitly object with hash parameter.

    my $bitly = WebService::Bitly->new(
        user_name        => 'shibayu36',
        user_api_key     => 'R_1234567890abcdefg',
        end_user_name    => 'bitly_end_user',
        end_user_api_key => 'R_abcdefg123456789',
        domain           => 'j.mp',
    );

following parameters are taken.

=over 4

=item user_name

Required parameter.  bit.ly user name.

=item user_api_key

Required parameter.  bit.ly user api key.

=item end_user_name

Optional parameter.  bit.ly end-user name.  This paramter used by shorten and validate method.

=item end_user_api_key

Optional parameter.  bit.ly end-user api key.  This paramter used by shorten and validate method.

=item domain

Optional parameter.  Specify 'j.mp', if you want to use j.mp domain in shorten method.

=back

=head2 shorten($url)

Get shorten result by long url.  you can make requests on behalf of another bit.ly user,  if you specify end_user_name and end_user_api_key in new or set_end_user_info method.

    my $result_shorten = $bitly->shorten('http://example.com');
    if (!$result_shorten->is_error) {
        print $result_shorten->short_url;
        print $result_shorten->hash;
    }

You can get data by following method of result object.

=over 4

=item is_error : return 1, if request is failed.

=item short_url : shortened url.

=item is_new_hash : return 1, if specified url was shortened first time.

=item hash

=item global_hash

=item long_url

=back

=head2 expand(%param)

=head2 validate

=head2 set_end_user_info($end_user_name, $end_user_api_key)

=head2 clicks(%param)

=head2 bitly_pro_domain($domain)

=head2 lookup(@urls)

=head2 info(%param)

=head2 authenticate($end_user_name, $end_user_password)

=head1 SEE ALSO

=head1 AUTHOR

Yuki Shibazaki, C<< <shiba1029196473 at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Yuki Shibazaki.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
