package Test::Function;
use strict;
use warnings;

use Test::More;
use WebService::Bitly;
use IO::Prompt;
use IO::File;

use base qw(Test::Class Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw( args ));

sub api_input : Test(startup) {
    my $self = shift;

    #APIキーやusernameの入力
    my $user_name        = prompt 'input bit.ly user name: ';
    my $user_api_key     = prompt 'input bit.ly user api key:';

    $self->{args} = {
        user_name        => $user_name,
        user_api_key     => $user_api_key,
        end_user_name    => $user_name,
        end_user_api_key => $user_api_key,
    };
}

sub test_020_instance : Test(5) {
    my $self = shift;
    my $args = $self->args;
    ok my $bitly = WebService::Bitly->new(%$args);
    is $bitly->user_name, $args->{user_name}, 'can get correct user_name';
    is $bitly->user_api_key, $args->{user_api_key}, 'can get correct user_api_key';
    is $bitly->end_user_name, $args->{end_user_name}, 'can get correct end_user_name';
    is $bitly->end_user_api_key, $args->{end_user_api_key}, 'can get correct end_user_api_key';
    is $bitly->domain, $args->{domain}, 'can get correct domain';
}

sub test_021_shorten : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten = $bitly->shorten('http://example.com/');
    ok !$result_shorten->is_error, 'not http error';
    ok $result_shorten->short_url =~ m{^http://bit[.]ly/\w{6}}, 'can get correct short_url';
    is $result_shorten->long_url, 'http://example.com/', 'can get correct long_url';

    #fail shorten
    ok $bitly = WebService::Bitly->new(%$args);
    $bitly->base_url('aaa');
    ok $result_shorten = $bitly->shorten('http://example.com/');
    ok $result_shorten->is_error, 'http error occured';
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
    ok my $validate_result = $bitly->validate_end_user_info;
    ok $validate_result->is_valid;

    ok $bitly->set_end_user_info('test', 'test'), 'both parameter are invalid';
    ok !$bitly->validate_end_user_info->is_valid;

#     $bitly->set_end_user_info('', $args->{end_user_name});
#     ok $bitly->validate_end_user_info->is_valid;

#     $bitly->set_end_user_info($args->{end_user_api_key}, '');
#     ok $bitly->validate_end_user_info->is_valid;

#     $bitly->set_end_user_info('', '');
#     ok $bitly->validate_end_user_info->is_valid, 'both parameter are empty';
}

sub test_024_expand : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten1 = $bitly->shorten('http://example1.com');
    ok my $result_shorten2 = $bitly->shorten('http://example2.com');

    ok my $result_expand = $bitly->expand(
        short_urls => [($result_shorten1->short_url, $result_shorten2->short_url)],
        hashes       => [($result_shorten1->hash, $result_shorten2->hash)],
    );
    ok !$result_expand->is_error;

    my @expand_list = $result_expand->expand_list;

    is $expand_list[0]->long_url, 'http://example1.com';
    is $expand_list[1]->long_url, 'http://example2.com';
    is $expand_list[2]->long_url, 'http://example1.com';
    is $expand_list[3]->long_url, 'http://example2.com';
}

sub test_025_clicks : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $result_shorten = $bitly->shorten('http://example1.com');

    ok my $result_clicks = $bitly->clicks(
        short_urls => [$result_shorten->short_url, 'http://foobarbaz.jp/a35.akasa'],
        hashes       => [$result_shorten->hash, 'a35.akasa'],
    );
    ok !$result_clicks->is_error;

    my @clicks_list = $result_clicks->clicks_list;

    ok !$clicks_list[0]->is_error, 'error should not  occur';
    is $clicks_list[0]->short_url, $result_shorten->short_url, 'should get correct short_url';
    is $clicks_list[0]->user_clicks, 0, 'should get user clicks';
    is $clicks_list[0]->global_clicks, 0, 'should get global clicks';
    
    ok $clicks_list[1]->is_error, 'error should occur';
    
    ok !$clicks_list[2]->is_error, 'error should not  occur';
    is $clicks_list[2]->hash, $result_shorten->hash, 'should get correct hash';
    is $clicks_list[2]->user_clicks, 0, 'should get user clicks';
    is $clicks_list[2]->global_clicks, 0, 'should get global clicks';
    
    ok $clicks_list[3]->is_error, 'error should occur';
}

sub test_026_bitly_pro_domain : Tests {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    is $bitly->bitly_pro_domain('nyti.ms')->is_pro_domain, 1, 'should pro doman';
    is $bitly->bitly_pro_domain('bit.ly')->is_pro_domain, 0, 'should not pro domain';
}

__PACKAGE__->runtests;

1;
