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

ok my $bitly = WebService::Bitly->new($args);
is $bitly->user_name, $args->{user_name}, 'can get correct user_name';
is $bitly->user_api_key, $args->{user_api_key}, 'can get correct user_api_key';
is $bitly->end_user_name, $args->{end_user_name}, 'can get correct end_user_name';
is $bitly->end_user_api_key, $args->{end_user_api_key}, 'can get correct end_user_api_key';
is $bitly->domain, $args->{domain}, 'can get correct domain';
