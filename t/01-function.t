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

use WebService::Bitly;


use base qw(Test::Class Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw( args ));

sub api_input : Test(startup) {
    my $self = shift;

    #APIキーやusernameの入力
    my $user_name        = prompt 'input bit.ly test user name: ', -d => '', -raw;
    my $user_api_key     = prompt 'input bit.ly test user api key:', -d => '', -raw;

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

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

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

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

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

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(
        user_name => $args->{user_name},
        user_api_key => $args->{user_api_key},
    );
    ok $bitly->set_end_user_info($args->{end_user_name}, $args->{end_user_api_key});
    is $bitly->end_user_name, $args->{end_user_name};
    is $bitly->end_user_api_key, $args->{end_user_api_key};
}

sub test_013_validate : Test(9) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $validate_result = $bitly->validate;
    isa_ok $validate_result, 'WebService::Bitly::Result::Validate', 'is correct object';
    ok $validate_result->is_valid;

    ok $bitly->set_end_user_info('test', 'test'), 'both parameter are invalid';
    ok !$bitly->validate->is_valid;

    $bitly->set_end_user_info('', $args->{end_user_name});
    ok $bitly->validate->is_error;

    $bitly->set_end_user_info($args->{end_user_api_key}, '');
    ok $bitly->validate->is_error;

    $bitly->set_end_user_info('', '');
    ok $bitly->validate->is_error, 'both parameter are empty';
}

sub test_014_expand : Test(10) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten1 = $bitly->shorten('http://code.google.com/p/bitly-api/wiki/ApiDocumentation');
    ok my $result_shorten2 = $bitly->shorten('http://www.google.co.jp/');

    ok my $result_expand = $bitly->expand(
        short_urls => [($result_shorten1->short_url, $result_shorten2->short_url)],
        hashes       => [($result_shorten1->hash, $result_shorten2->hash)],
    );
    isa_ok $result_expand, 'WebService::Bitly::Result::Expand', 'is correct object';
    ok !$result_expand->is_error;

    my @expand_list = $result_expand->results;

    is $expand_list[0]->long_url, 'http://code.google.com/p/bitly-api/wiki/ApiDocumentation';
    is $expand_list[1]->long_url, 'http://www.google.co.jp/';
    is $expand_list[2]->long_url, 'http://code.google.com/p/bitly-api/wiki/ApiDocumentation';
    is $expand_list[3]->long_url, 'http://www.google.co.jp/';
}

sub test_015_clicks : Test(13) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten = $bitly->shorten('http://code.google.com/p/bitly-api/wiki/ApiDocumentation');

    ok my $result_clicks = $bitly->clicks(
        short_urls => [$result_shorten->short_url, 'http://foobarbaz.jp/a35.akasa'],
        hashes       => [$result_shorten->hash, 'a35.akasa'],
    );
    isa_ok $result_clicks, 'WebService::Bitly::Result::Clicks', 'is correct object';
    ok !$result_clicks->is_error;

    my @clicks_list = $result_clicks->results;
    #You can't map the responses by order, response order is not guaranteed.
    #to test the responses you have to match what was sent to what was echoed back by the server.
    my ($result_valid_short_url) = grep
        { defined $_->short_url && $_->short_url eq $result_shorten->short_url } @clicks_list;
    my ($result_invalid_short_url) = grep
        { defined $_->short_url && $_->short_url eq 'http://foobarbaz.jp/a35.akasa' } @clicks_list;
    my ($result_valid_hash) = grep
        { defined $_->hash && $_->hash eq $result_shorten->hash } @clicks_list;
    my ($result_invalid_hash) = grep
        { defined $_->hash && $_->hash eq 'a35.akasa' } @clicks_list;
    ok !$result_valid_short_url->is_error, 'error should not occur';
    #Busted
    is $result_valid_short_url->short_url, $result_shorten->short_url, 'should get correct short_url';
    ok $result_valid_short_url->global_clicks, 'should get global clicks';

    ok $result_invalid_short_url->is_error, 'error should occur';

    ok !$result_valid_hash->is_error, 'error should not  occur';
    is $result_valid_hash->hash, $result_shorten->hash, 'should get correct hash';
    ok $result_valid_hash->global_clicks, 'should get global clicks';

    ok $result_invalid_hash->is_error, 'error should occur';
}

sub test_016_bitly_pro_domain : Tests {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(%$args);

    is $bitly->bitly_pro_domain('nyti.ms')->is_pro_domain, 1, 'should pro doman';
    is $bitly->bitly_pro_domain('bit.ly')->is_pro_domain, 0, 'should not pro domain';
}

sub test_017_lookup : Test(10) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten1 = $bitly->shorten('http://code.google.com/p/bitly-api/wiki/ApiDocumentation');
    ok my $result_shorten2 = $bitly->shorten('http://www.google.co.jp/');

    ok my $lookup = $bitly->lookup([
        'http://code.google.com/p/bitly-api/wiki/ApiDocumentation',
        'http://www.google.co.jp/',
    ]);

    isa_ok $lookup, 'WebService::Bitly::Result::Lookup', 'is correct object';
    ok !$lookup->is_error;

    my @lookup = $lookup->results;

    is $lookup[0]->global_hash, $result_shorten1->global_hash, 'should get correct global hash';
    is $lookup[0]->short_url, 'http://bit.ly/'.$result_shorten1->global_hash, 'should get correct short url';
    is $lookup[1]->global_hash, $result_shorten2->global_hash, 'should get correct global hash';
    is $lookup[1]->short_url, 'http://bit.ly/'.$result_shorten2->global_hash, 'should get correct short url';
}

sub test_018_authenticate : Test(9) {
    my $self = shift;
    my $args = $self->args;
    return("this test cannot succeeded, unless user allow authenticate access.");

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $authenticate = $bitly->authenticate('bitlyapidemo', 'good-password');

    ok !$authenticate->is_error, 'error should not occur';
    ok $authenticate->is_success, 'authenticate should be success';
    is $authenticate->user_name, $args->{end_user_name}, 'user name should be correct';
    is $authenticate->api_key, $args->{end_user_api_key}, 'user api key should be correct';

    ok $authenticate = $bitly->authenticate('bitlyapidemo', 'bad-password');
    ok !$authenticate->is_error, 'error should not occur';
    ok !$authenticate->is_success, 'authenticate should not be success';
}

sub test_019_info : Test(15) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten = $bitly->shorten('http://www.google.co.jp/');

    ok my $result_info = $bitly->info(
        short_urls   => [$result_shorten->short_url, 'http://bit.ly/bad-url.'],
        hashes       => [$result_shorten->hash, 'bad-url.'],
    );
    isa_ok $result_info, 'WebService::Bitly::Result::Info', 'is correct object';
    ok !$result_info->is_error;

    my @info_list = $result_info->results;

    ok !$info_list[0]->is_error, 'error should not occur';
    is $info_list[0]->title, 'Google', 'should get correct title';
    is $info_list[0]->user_hash, $result_shorten->hash, 'should get correct short url';
    ok $info_list[0]->created_by, 'should get created_by';

    ok $info_list[1]->is_error;

    ok !$info_list[2]->is_error, 'error should not occur';
    is $info_list[2]->title, 'Google', 'should get correct title';
    is $info_list[2]->short_url, $result_shorten->short_url, 'should get correct hash';
    ok $info_list[2]->created_by, 'should get created_by';

    ok $info_list[3]->is_error;
}

sub test_020_http_error : Test(3) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );
    $bitly->{base_url} = 'aaa';

    my $shorten = $bitly->shorten('http://www.google.co.jp/');
    isa_ok $shorten, 'WebService::Bitly::Result::HTTPError', 'is correct object';
    ok $shorten->is_error, 'error should occur';
}

sub test_021_referrers : Test(17) {
    my $self = shift;
    my $args = $self->args;

    if (!$args->{user_name} && !$args->{user_api_key}) {
        return 'user name and api key are both required';
    }

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

    # check bit.ly access
    my $result_referrer = $bitly->referrers(short_url => 'http://bit.ly/djZ9g4');
    ok $result_referrer->global_hash, 'can access global hash';
    ok $result_referrer->short_url, 'can access short_url';
    ok $result_referrer->user_hash, 'can access user hash';
    ok $result_referrer->referrers, 'can access referrers';

    # check whether to be able to use accessor method
    my $data = $self->{data}->{referrers};
    $result_referrer = initialize_result_class('Referrers', $data);
    is $result_referrer->created_by, $data->{data}->{created_by}, 'correct created_by';
    is $result_referrer->global_hash, $data->{data}->{global_hash}, 'correct global_hash';
    is $result_referrer->short_url, $data->{data}->{short_url}, 'correct short_url';
    is $result_referrer->user_hash, $data->{data}->{user_hash}, 'correct user_hash';

    my $referrers = $result_referrer->referrers;
    is $referrers->[0]->clicks, $data->{data}->{referrers}->[0]->{clicks}, 'correct clicks';
    is $referrers->[0]->referrer, $data->{data}->{referrers}->[0]->{referrer}, 'correct referrer';
    is $referrers->[0]->referrer_app, $data->{data}->{referrers}->[0]->{referrer_app}, 'correct referrer_app';
    is $referrers->[0]->url, $data->{data}->{referrers}->[0]->{url}, 'correct url';
    is $referrers->[1]->clicks, $data->{data}->{referrers}->[1]->{clicks}, 'correct clicks';
    is $referrers->[1]->referrer, $data->{data}->{referrers}->[1]->{referrer}, 'correct referrer';
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
