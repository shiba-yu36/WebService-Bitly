use strict;
use warnings;
use inc::Module::Install;

name     'WebService-Bitly';
author   'Yuki Shibazaki <shiba1029196473@gmail.com>';
all_from 'lib/WebService/Bitly.pm';

requires 'URI';
requires 'URI::QueryParam';
requires 'LWP::UserAgent';
requires 'JSON';
requires 'Class::Accessor::Fast';
requires 'JSON';

test_requires 'Test::More';
test_requires 'Test::Class';
test_requires 'IO::Prompt';

auto_install;
WriteAll;
