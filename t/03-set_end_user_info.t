use strict;
use warnings;

use Test::More qw/no_plan/;
use WebService::Bitly;

my $args = {
    user_name => 'webservicebitlyuser',
    user_api_key => 'R_40e8f7bb2f864248add7e3119ac12ea4',
    end_user_name => 'webservicebitlyenduser',
    end_user_api_key => 'R_7a0016587783a1cf72853d8004367e08',
    domain => 'j.mp',
};

ok my $bitly = WebService::Bitly->new(
        user_name => 'hatenadev',
        user_api_key => 'R_ea19c4f813f6db6aeb4d58c5197f3c7f',
    );
    ok $bitly->set_end_user_info($args->{end_user_name}, $args->{end_user_api_key});
    is $bitly->end_user_name, $args->{end_user_name};
    is $bitly->end_user_api_key, $args->{end_user_api_key};
