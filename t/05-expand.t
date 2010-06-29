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

my $bitly;

ok $bitly = WebService::Bitly->new(%$args);
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
