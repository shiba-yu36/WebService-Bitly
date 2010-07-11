use strict;
use warnings;
use inc::Module::Install;

name     'WebService-Bitly';
author   'Yuki Shibazaki <shiba1029196473@gmail.com>';
all_from 'lib/WebService/Bitly.pm';

auto_install;
WriteAll;
