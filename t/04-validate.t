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
ok my $validate_result = $bitly->validate_end_user_info;
ok $validate_result->is_valid;

ok $bitly->set_end_user_info('test', 'test'), 'both parameter are invalid';
ok !$bitly->validate_end_user_info->is_valid;

# $bitly->set_end_user_info('', 'R_d45bca581ce2c8215d220f46dbe96c5e'), 'end_user_name is empty';
# ok $bitly->validate_end_user_info->is_valid;

# $bitly->set_end_user_info('shibayu36', ''), 'end_user_api_key is empty';
# ok $bitly->validate_end_user_info->is_valid;

# $bitly->set_end_user_info('', '');
# ok $bitly->validate_end_user_info->is_valid, 'both parameter are empty';
