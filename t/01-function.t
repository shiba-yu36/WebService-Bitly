package Test::Function;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::WebService::Bitly;
use Test::WebService::Bitly::Mock::UserAgent;
use Test::More;
use Test::Exception;
use IO::Prompt;
use YAML::Syck;
use Path::Class qw(file);
use JSON;

use WebService::Bitly;


use base qw(Test::Class Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw( args ));

sub api_input : Test(startup) {
    my $self = shift;

    my $user_name    = 'test_user';
    my $user_api_key = 'test_key';

    $self->{args} = {
        user_name         => $user_name,
        user_api_key      => $user_api_key,
        end_user_name     => $user_name,
        end_user_api_key  => $user_api_key,
        ua                => Test::WebService::Bitly::Mock::UserAgent->new,
    };

    my $data_file = file(__FILE__)->dir->subdir('data')->file('response.yml');
    $self->{data} = LoadFile($data_file->stringify);
}

sub test_010_instance : Test(8) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
        domain  => 'j.mp',
        version => 'v3',
    );

    isa_ok $bitly, 'WebService::Bitly', 'is correct object';
    is $bitly->user_name, $args->{user_name}, 'can get correct user_name';
    is $bitly->user_api_key, $args->{user_api_key}, 'can get correct user_api_key';
    is $bitly->end_user_name, $args->{end_user_name}, 'can get correct end_user_name';
    is $bitly->end_user_api_key, $args->{end_user_api_key}, 'can get correct end_user_api_key';
    is $bitly->domain, 'j.mp', 'can get correct domain';
    is $bitly->version, 'v3', 'can get correct version';
}

sub test_011_shorten : Test(9) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten = $bitly->shorten('http://betaworks.com/');

    isa_ok $result_shorten, 'WebService::Bitly::Result::Shorten', 'is correct object';
    ok !$result_shorten->is_error, 'not http error';
    is $result_shorten->short_url, 'http://bit.ly/cmeH01', 'can get correct short_url';
    is $result_shorten->hash, 'cmeH01', 'can get correct hash';
    is $result_shorten->global_hash, '1YKMfY', 'can get correct gobal hash';
    is $result_shorten->long_url, 'http://betaworks.com/', 'can get correct long url';
    is $result_shorten->is_new_hash, 0, 'can get correct new hash';
}

sub test_012_set_end_user_info : Test(4) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        user_name => $args->{user_name},
        user_api_key => $args->{user_api_key},
    );
    ok $bitly->set_end_user_info($args->{end_user_name}, $args->{end_user_api_key});
    is $bitly->end_user_name, $args->{end_user_name};
    is $bitly->end_user_api_key, $args->{end_user_api_key};
}

sub test_013_validate : Test(4) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $validate_result = $bitly->validate;
    isa_ok $validate_result, 'WebService::Bitly::Result::Validate', 'is correct object';
    ok $validate_result->is_valid;
}

sub test_014_expand : Test(10) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    ok my $result_expand = $bitly->expand(
        short_urls => ['http://tcrn.ch/a4MSUH'],
        hashes     => ['a35.'],
    );
    isa_ok $result_expand, 'WebService::Bitly::Result::Expand', 'is correct object';
    ok !$result_expand->is_error;

    my @expand_list = $result_expand->results;

    is $expand_list[0]->short_url, 'http://tcrn.ch/a4MSUH', 'correct short_url';
    is $expand_list[0]->global_hash, 'bWw49z', 'correct global_hash';
    is $expand_list[0]->long_url, 'http://www.techcrunch.com/2010/01/29/windows-mobile-foursquare/', 'correct long_url';
    is $expand_list[0]->user_hash, 'a4MSUH', 'correct user_hash';

    ok $expand_list[1]->is_error, 'error should occur';
}

sub test_015_clicks : Test(11) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    ok my $result_clicks = $bitly->clicks(
        short_urls => ['http://tcrn.ch/a4MSUH'],
        hashes     => ['a35.'],
    );
    isa_ok $result_clicks, 'WebService::Bitly::Result::Clicks', 'is correct object';
    ok !$result_clicks->is_error;

    my @clicks_list = $result_clicks->results;
    is $clicks_list[0]->short_url, 'http://tcrn.ch/a4MSUH', 'correct short_url';
    is $clicks_list[0]->global_hash, 'bWw49z', 'correct global_hash';
    is $clicks_list[0]->user_clicks, '0', 'correct user_clicks';
    is $clicks_list[0]->user_hash, 'a4MSUH', 'correct user_hash';
    is $clicks_list[0]->global_clicks, '1105', 'correct global_clicks';

    is $clicks_list[1]->hash, 'a35.', 'correct hash';
    ok $clicks_list[1]->is_error, 'error should occur';
}

sub test_016_bitly_pro_domain : Test(3) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    my $pro_result = $bitly->bitly_pro_domain('nyti.ms');

    is $pro_result->is_pro_domain, 1, 'should pro domain';

    $pro_result->{data}->{bitly_pro_domain} = 0;
    is $pro_result->is_pro_domain, 0, 'should not pro domain';
}

sub test_017_lookup : Test(8) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    ok my $lookup = $bitly->lookup([
        'http://betaworks.com/',
        'asdf://www.google.com/not/a/real/link',
    ]);

    isa_ok $lookup, 'WebService::Bitly::Result::Lookup', 'is correct object';
    ok !$lookup->is_error;

    my @lookup = $lookup->results;

    is $lookup[0]->global_hash, 'beta', 'correct global_hash';
    is $lookup[0]->short_url, 'http://bit.ly/beta', 'correct short_url';
    is $lookup[0]->url, 'http://betaworks.com/', 'correct url';
    ok $lookup[1]->is_error, 'error should occur';
}

sub test_018_authenticate : Test(8) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $authenticate = $bitly->authenticate('bitlyapidemo', 'good-password');
    isa_ok $authenticate, 'WebService::Bitly::Result::Authenticate', 'is correct object';

    ok !$authenticate->is_error, 'error should not occur';
    ok $authenticate->is_success, 'authenticate should be success';
    is $authenticate->user_name, 'bitlyapidemo', 'user name should be correct';
    is $authenticate->api_key, 'R_0da49e0a9118ff35f52f629d2d71bf07', 'user api key should be correct';

    $authenticate->{data}->{authenticate}->{successful} = JSON::false;
    ok !$authenticate->is_success, 'authenticate should not be success';
}

sub test_019_info : Test(13) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    ok my $result_info = $bitly->info(
        short_urls   => ['http://bit.ly/a.35'],
        hashes       => ['j3'],
    );
    isa_ok $result_info, 'WebService::Bitly::Result::Info', 'is correct object';
    ok !$result_info->is_error;
    isa_ok $result_info, 'WebService::Bitly::Result::Info', 'is correct object';

    my @info_list = $result_info->results;

    is $info_list[0]->short_url, 'http://bit.ly/a.35', 'correct short_url';
    ok $info_list[0]->is_error, 'error should occur';

    ok !$info_list[1]->is_error, 'error should not occur';
    is $info_list[1]->created_by, 'scotster', 'should get created_by';
    is $info_list[1]->global_hash, 'lLWr', 'should get correct global_hash';
    is $info_list[1]->hash, 'j3', 'should get correct hash';
    is $info_list[1]->title, 'test title', 'should get correct title';
    is $info_list[1]->user_hash, 'j3', 'should get correct short url';
}

sub test_020_http_error : Test(3) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );
    $bitly->{base_url} = 'http://aaa/';

    my $shorten = $bitly->shorten('http://www.google.co.jp/');
    isa_ok $shorten, 'WebService::Bitly::Result::HTTPError', 'is correct object';
    ok $shorten->is_error, 'error should occur';
}

sub test_021_referrers : Test(11) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );

    dies_ok(sub {$bitly->refferers}, 'Either short_url or hash is required');
    dies_ok(sub {
        $bitly->refferers(
            short_url => 'http://bit.ly/djZ9g4',
            hash      => 'djZ9g4',
        );
    }, 'Either short_url or hash is required');

    my $result_referrer = $bitly->referrers(short_url => 'http://bit.ly/djZ9g4');
    is $result_referrer->global_hash, 'djZ9g4', 'can access global hash';
    is $result_referrer->short_url, 'http://bit.ly/djZ9g4', 'can access short_url';
    is $result_referrer->user_hash, 'djZ9g4', 'can access user hash';

    my $referrers = $result_referrer->referrers;
    is $referrers->[0]->clicks, 42, 'correct clicks';
    is $referrers->[0]->referrer, 'direct', 'correct referrer';
    is $referrers->[1]->clicks, 8, 'correct clicks';
    is $referrers->[1]->referrer_app, 'TweetDeck', 'correct referrer_app';
    is $referrers->[1]->url, 'http://www.tweetdeck.com/', 'correct url';
}

sub test_022_countries : Test(14) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );

    dies_ok(sub {$bitly->countries}, 'Either short_url or hash is required');
    dies_ok(sub {
        $bitly->countries(
            short_url => 'http://bit.ly/djZ9g4',
            hash      => 'djZ9g4',
        );
    }, 'Either short_url or hash is required');

    my $result_country = $bitly->countries(hash => 'djZ9g4');
    ok $result_country->global_hash, 'can access global hash';
    ok $result_country->user_hash, 'can access user hash';
    ok $result_country->countries, 'can access countries';

    my $data = $self->{data}->{countries};
    my $result_countries = initialize_result_class('Countries', $data);
    is $result_countries->created_by, $data->{data}->{created_by}, 'correct created_by';
    is $result_countries->global_hash, $data->{data}->{global_hash}, 'correct global_hash';
    is $result_countries->short_url, $data->{data}->{short_url}, 'correct short_url';
    is $result_countries->user_hash, $data->{data}->{user_hash}, 'correct user_hash';

    my $countries = $result_countries->countries;
    is $countries->[0]->clicks, $data->{data}->{countries}->[0]->{clicks}, 'correct clicks';
    is $countries->[0]->country, $data->{data}->{countries}->[0]->{country}, 'correct country';
    is $countries->[1]->clicks, $data->{data}->{countries}->[1]->{clicks}, 'correct clicks';
    is $countries->[1]->country, $data->{data}->{countries}->[1]->{country}, 'correct country';
}

sub test_023_clicks_by_minute : Test(21) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );

    dies_ok(sub {$bitly->clicks_by_minute}, 'Either short_url, hash or multi is required');

    ok my $result_shorten = $bitly->shorten('http://www.google.co.jp/');

    ok my $result_clicks = $bitly->clicks_by_minute(
        short_urls   => [$result_shorten->short_url, 'http://bit.ly/bad-url.'],
        hashes       => [$result_shorten->hash, 'bad-url.'],
    );

    isa_ok $result_clicks, 'WebService::Bitly::Result::ClicksByMinute', 'is correct object';
    ok !$result_clicks->is_error;

    my @clicks_list = $result_clicks->results;
    #You can't map the responses by order, response order is not guaranteed.
    #to test the responses you have to match what was sent to what was echoed back by the server.
    my ($result_valid_short_url) = grep
        { defined $_->short_url && $_->short_url eq $result_shorten->short_url } @clicks_list;
    my ($result_invalid_short_url) = grep
        { defined $_->short_url && $_->short_url eq 'http://bit.ly/bad-url.' } @clicks_list;
    my ($result_valid_hash) = grep
        { defined $_->hash && $_->hash eq $result_shorten->hash } @clicks_list;
    my ($result_invalid_hash) = grep
        { defined $_->hash && $_->hash eq 'bad-url.' } @clicks_list;

    ok !$result_valid_short_url->is_error, 'error should not occur';
    #Busted
    is $result_valid_short_url->short_url, $result_shorten->short_url, 'should get correct short_url';
    ok $result_valid_short_url->clicks, 'should get clicks';

    ok $result_invalid_short_url->is_error, 'error should occur';

    ok !$result_valid_hash->is_error, 'error should not occur';
    is $result_valid_hash->hash, $result_shorten->hash, 'should get correct hash';
    ok $result_valid_hash->clicks, 'should get global clicks';

    ok $result_invalid_hash->is_error, 'error should occur';

    # accessor test
    my $data = $self->{data}->{clicks_by_minute};
    $result_clicks = initialize_result_class('ClicksByMinute', $data);
    my $results = $result_clicks->results;
    my $clicks_by_minutes_data = $data->{data}->{clicks_by_minute};
    is $results->[0]->global_hash, $clicks_by_minutes_data->[0]->{global_hash}, 'is correct global hash';
    is $results->[0]->hash, $clicks_by_minutes_data->[0]->{hash}, 'is correct hash';
    is $results->[0]->short_url, $clicks_by_minutes_data->[0]->{short_url}, 'is correct short_url';
    is $results->[0]->user_hash, $clicks_by_minutes_data->[0]->{user_hash}, 'is correct user_hash';
    is $results->[0]->clicks->[0], $clicks_by_minutes_data->[0]->{clicks}->[0], 'is correct clicks';
    is $results->[0]->clicks->[1], $clicks_by_minutes_data->[0]->{clicks}->[1], 'is correct clicks';
    is $results->[0]->clicks->[2], $clicks_by_minutes_data->[0]->{clicks}->[2], 'is correct clicks';
}

sub test_024_clicks_by_day : Test(22) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );

    dies_ok(sub {$bitly->clicks_by_day}, 'Either short_url, hash or multi is required');

    ok my $result_shorten = $bitly->shorten('http://www.google.co.jp/');

    ok my $result_clicks = $bitly->clicks_by_day(
        short_urls   => [$result_shorten->short_url, 'http://bit.ly/bad-url.'],
        hashes       => [$result_shorten->hash, 'bad-url.'],
    );

    isa_ok $result_clicks, 'WebService::Bitly::Result::ClicksByDay', 'is correct object';
    ok !$result_clicks->is_error;

    my @clicks_list = $result_clicks->results;
    #You can't map the responses by order, response order is not guaranteed.
    #to test the responses you have to match what was sent to what was echoed back by the server.
    my ($result_valid_short_url) = grep
        { defined $_->short_url && $_->short_url eq $result_shorten->short_url } @clicks_list;
    my ($result_invalid_short_url) = grep
        { defined $_->short_url && $_->short_url eq 'http://bit.ly/bad-url.' } @clicks_list;
    my ($result_valid_hash) = grep
        { defined $_->hash && $_->hash eq $result_shorten->hash } @clicks_list;
    my ($result_invalid_hash) = grep
        { defined $_->hash && $_->hash eq 'bad-url.' } @clicks_list;

    ok !$result_valid_short_url->is_error, 'error should not occur';
    #Busted
    is $result_valid_short_url->short_url, $result_shorten->short_url, 'should get correct short_url';
    ok $result_valid_short_url->clicks, 'should get clicks';

    ok $result_invalid_short_url->is_error, 'error should occur';

    ok !$result_valid_hash->is_error, 'error should not occur';
    is $result_valid_hash->hash, $result_shorten->hash, 'should get correct hash';
    ok $result_valid_hash->clicks, 'should get global clicks';

    ok $result_invalid_hash->is_error, 'error should occur';

    # accessor test
    my $data = $self->{data}->{clicks_by_day};
    $result_clicks = initialize_result_class('ClicksByDay', $data);
    my $results = $result_clicks->results;
    my $clicks_by_day_data = $data->{data}->{clicks_by_day};
    is $results->[0]->global_hash, $clicks_by_day_data->[0]->{global_hash}, 'is correct global hash';
    is $results->[0]->hash, $clicks_by_day_data->[0]->{hash}, 'is correct hash';
    is $results->[0]->short_url, $clicks_by_day_data->[0]->{short_url}, 'is correct short_url';
    is $results->[0]->user_hash, $clicks_by_day_data->[0]->{user_hash}, 'is correct user_hash';

    my $clicks = $results->[0]->clicks;
    is $clicks->[0]->clicks, $clicks_by_day_data->[0]->{clicks}->[0]->{clicks}, 'is correct clicks';
    is $clicks->[0]->day_start, $clicks_by_day_data->[0]->{clicks}->[0]->{day_start}, 'is correct day start';
    is $clicks->[1]->clicks, $clicks_by_day_data->[0]->{clicks}->[1]->{clicks}, 'is correct clicks';
    is $clicks->[1]->day_start, $clicks_by_day_data->[0]->{clicks}->[1]->{day_start}, 'is correct day start';
}

__PACKAGE__->runtests;

1;
