package Test::WebService::Bitly;
use strict;
use warnings;

use FindBin;
use lib      "$FindBin::Bin/../../../lib";
use lib glob "$FindBin::Bin/../../../modules/*/lib";

use Test::More;
use WebService::Bitly;

use base qw(Test::Class);

my $args = {
    user_name => 'webservicebitlyuser',
    user_api_key => 'R_40e8f7bb2f864248add7e3119ac12ea4',
    end_user_name => 'webservicebitlyenduser',
    end_user_api_key => 'R_7a0016587783a1cf72853d8004367e08',
    domain => 'j.mp',
};

sub new_test : Tests(6) {
    ok my $bitly = WebService::Bitly->new($args);
    is $bitly->user_name, $args->{user_name}, 'can get correct user_name';
    is $bitly->user_api_key, $args->{user_api_key}, 'can get correct user_api_key';
    is $bitly->end_user_name, $args->{end_user_name}, 'can get correct end_user_name';
    is $bitly->end_user_api_key, $args->{end_user_api_key}, 'can get correct end_user_api_key';
    is $bitly->domain, $args->{domain}, 'can get correct domain';
}

sub shorten_success_test : Tests(5) {
    ok my $bitly = WebService::Bitly->new($args);
    ok my $result_shorten = $bitly->shorten('http://example.com/');
    ok !$result_shorten->is_error, 'not http error';
    ok $result_shorten->shorten_url =~ m{^http://j[.]mp/\w{6}}, 'can get correct shorten_url';
    is $result_shorten->long_url, 'http://example.com/', 'can get correct long_url';
    use YAML;
    warn YAML::Dump($result_shorten);
}

sub shorten_error_test : Tests {
    ok my $bitly = WebService::Bitly->new($args);
    $bitly->base_url('aaa');
    
    ok my $result_shorten = $bitly->shorten('http://example.com/');
    ok $result_shorten->is_error, 'http error occured';
}

sub set_end_user_info_test: Tests {
    ok my $bitly = WebService::Bitly->new({
        user_name => 'hatenadev',
        user_api_key => 'R_ea19c4f813f6db6aeb4d58c5197f3c7f',
    });
    ok $bitly->set_end_user_info($args->{end_user_name}, $args->{end_user_api_key});
    is $bitly->end_user_name, $args->{end_user_name};
    is $bitly->end_user_api_key, $args->{end_user_api_key};
}

sub validate_test : Tests {
    ok my $bitly = WebService::Bitly->new($args);
    ok my $validate_result = $bitly->validate_end_user_info;
    ok $validate_result->is_valid;

    $bitly->set_end_user_info('test', 'test'), 'both parameter are invalid';
    ok !$bitly->validate_end_user_info->is_valid;

    $bitly->set_end_user_info('', 'R_d45bca581ce2c8215d220f46dbe96c5e'), 'end_user_name is empty';
    ok $bitly->validate_end_user_info->is_valid;

    $bitly->set_end_user_info('shibayu36', ''), 'end_user_api_key is empty';
    ok $bitly->validate_end_user_info->is_valid;

    $bitly->set_end_user_info('', '');
    ok $bitly->validate_end_user_info->is_valid, 'both parameter are empty';
}

__PACKAGE__->runtests;

1;
