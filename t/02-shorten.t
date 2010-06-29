use strict;
use warnings;

use Test::More qw/no_plan/;
use WebService::Bitly;

my $args = {
    user_name => 'webservicebitlyuser',
    user_api_key => 'R_40e8f7bb2f864248add7e3119ac12ea4',
    end_user_name => 'webservicebitlyenduser',
    end_user_api_key => 'R_7a0016587783a1cf72853d8004367e08'
        ,
    domain => 'j.mp',
};

#success shorten
ok my $bitly = WebService::Bitly->new($args);
ok my $result_shorten = $bitly->shorten('http://example.com/');
ok !$result_shorten->is_error, 'not http error';
ok $result_shorten->shorten_url =~ m{^http://j[.]mp/\w{6}}, 'can get correct shorten_url';
is $result_shorten->long_url, 'http://example.com/', 'can get correct long_url';

#fail shorten
ok $bitly = WebService::Bitly->new($args);
$bitly->base_url('aaa');
ok $result_shorten = $bitly->shorten('http://example.com/');
ok $result_shorten->is_error, 'http error occured';
