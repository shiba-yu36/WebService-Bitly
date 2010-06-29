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
ok my $result_shorten = $bitly->shorten('http://example.com');

ok my $result_expand = $bitly->expand($result_shorten->shorten_url);
ok !$result_expand->is_error;
is $result_expand->expand_url, 'http://example.com';
