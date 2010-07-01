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
    my $end_user_name    = prompt 'input bit.ly end user name: ';
    my $end_user_api_key = prompt 'input bit.ly end user api key: ';

    $self->{args} = {
        user_name        => $user_name,
        user_api_key     => $user_api_key,
        end_user_name    => $end_user_name,
        end_user_api_key => $end_user_api_key,
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
    ok $result_shorten->shorten_url =~ m{^http://bit[.]ly/\w{6}}, 'can get correct shorten_url';
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
        shorten_urls => [($result_shorten1->shorten_url, $result_shorten2->shorten_url)],
        hashes       => [($result_shorten1->hash, $result_shorten2->hash)],
    );
    ok !$result_expand->is_error;

    my @expand_lists = $result_expand->expand_lists;

    is $expand_lists[0]->long_url, 'http://example1.com';
    is $expand_lists[1]->long_url, 'http://example2.com';
    is $expand_lists[2]->long_url, 'http://example1.com';
    is $expand_lists[3]->long_url, 'http://example2.com';
}

sub test_025_clicks : Tests {
    my $self = shift;
    my $args = $self->args;

}

__PACKAGE__->runtests;

1;
