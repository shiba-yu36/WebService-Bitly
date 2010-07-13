package Test::Function;
use strict;
use warnings;

use Test::More;
use WebService::Bitly;
use IO::Prompt;

use base qw(Test::Class Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw( args ));

sub api_input : Test(startup) {
    my $self = shift;

    #APIキーやusernameの入力
    my $user_name        = prompt 'input bit.ly test user name: ';
    my $user_api_key     = prompt 'input bit.ly test user api key:';

    $self->{args} = {
        user_name         => $user_name,
        user_api_key      => $user_api_key,
        end_user_name     => $user_name,
        end_user_api_key  => $user_api_key,
    };
}

sub test_020_instance : Test(5) {
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

sub test_021_shorten : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten = $bitly->shorten('http://code.google.com/p/bitly-api/wiki/ApiDocumentation');

    isa_ok $result_shorten, 'WebService::Bitly::Result::Shorten', 'is correct object';
    ok !$result_shorten->is_error, 'not http error';
    ok $result_shorten->short_url =~ m{^http://bit[.]ly/\w{6}}, 'can get correct short_url';
    is $result_shorten->long_url, 'http://code.google.com/p/bitly-api/wiki/ApiDocumentation', 'can get correct long_url';
}

sub test_022_set_end_user_info : Tests {
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

sub test_023_validate : Tests {
    my $self = shift;
    my $args = $self->args;

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

sub test_024_expand : Tests {
    my $self = shift;
    my $args = $self->args;

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

sub test_025_clicks : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten = $bitly->shorten('http://code.google.com/p/bitly-api/wiki/ApiDocumentation');

    ok my $result_clicks = $bitly->clicks(
        short_urls => [$result_shorten->short_url, 'http://foobarbaz.jp/a35.akasa'],
        hashes       => [$result_shorten->hash, 'a35.akasa'],
    );
    isa_ok $result_clicks, 'WebService::Bitly::Result::Clicks', 'is correct object';
    ok !$result_clicks->is_error;

    my @clicks_list = $result_clicks->results;

    ok !$clicks_list[0]->is_error, 'error should not  occur';
    is $clicks_list[0]->short_url, $result_shorten->short_url, 'should get correct short_url';
    ok $clicks_list[0]->global_clicks, 'should get global clicks';

    ok $clicks_list[1]->is_error, 'error should occur';

    ok !$clicks_list[2]->is_error, 'error should not  occur';
    is $clicks_list[2]->hash, $result_shorten->hash, 'should get correct hash';
    ok $clicks_list[2]->global_clicks, 'should get global clicks';

    ok $clicks_list[3]->is_error, 'error should occur';
}

sub test_026_bitly_pro_domain : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    is $bitly->bitly_pro_domain('nyti.ms')->is_pro_domain, 1, 'should pro doman';
    is $bitly->bitly_pro_domain('bit.ly')->is_pro_domain, 0, 'should not pro domain';
}

sub test_027_lookup : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten1 = $bitly->shorten('http://code.google.com/p/bitly-api/wiki/ApiDocumentation');
    ok my $result_shorten2 = $bitly->shorten('http://www.google.co.jp/');

    ok my $lookup = $bitly->lookup(
        'http://code.google.com/p/bitly-api/wiki/ApiDocumentation',
        'http://www.google.co.jp/',
    );

    isa_ok $lookup, 'WebService::Bitly::Result::Lookup', 'is correct object';
    ok !$lookup->is_error;

    my @lookup = $lookup->results;

    is $lookup[0]->global_hash, $result_shorten1->global_hash, 'should get correct global hash';
    is $lookup[0]->short_url, 'http://bit.ly/'.$result_shorten1->global_hash, 'should get correct short url';
    is $lookup[1]->global_hash, $result_shorten2->global_hash, 'should get correct global hash';
    is $lookup[1]->short_url, 'http://bit.ly/'.$result_shorten2->global_hash, 'should get correct short url';
}

sub test_028_authenticate : Tests {
    my $self = shift;
    my $args = $self->args;
    return("this test cannot succeeded, unless user allow authenticate access.");

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $authenticate = $bitly->authenticate($args->{end_user_name}, $self->{password});

    ok !$authenticate->is_error, 'error should not occur';
    ok $authenticate->is_success, 'authenticate should be success';
    is $authenticate->user_name, $args->{end_user_name}, 'user name should be correct';
    is $authenticate->api_key, $args->{end_user_api_key}, 'user api key should be correct';

    $bitly->set_end_user_info('error', 'error_api_key');
    ok $authenticate = $bitly->authenticate($args->{end_user_name}, $self->{password});
    ok !$authenticate->is_error, 'error should not occur';
    ok !$authenticate->is_success, 'authenticate should not be success'
}

sub test_029_info : Tests {
    my $self = shift;
    my $args = $self->args;

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

    ok $info_list[1]->is_error;

    ok !$info_list[2]->is_error, 'error should not occur';
    is $info_list[2]->title, 'Google', 'should get correct title';
    is $info_list[2]->short_url, $result_shorten->short_url, 'should get correct hash';

    ok $info_list[3]->is_error;
}

sub test_030_http_error : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
        base_url => 'aaa',
    );
    #fail shorten
    ok $bitly = WebService::Bitly->new(%$args);
}

__PACKAGE__->runtests;

1;
