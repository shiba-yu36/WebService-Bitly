use strict;
use warnings;
use inc::Module::Install;

name     'WebService-Bitly';
author   'Yuki Shibazaki <shibayu36@gmail.com>';
all_from 'lib/WebService/Bitly.pm';

requires 'Carp';
requires 'URI';
requires 'URI::QueryParam';
requires 'LWP::UserAgent';
requires 'JSON';
requires 'Class::Accessor::Fast';
requires 'JSON';
requires 'UNIVERSAL::require';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::Class';
test_requires 'IO::Prompt';
test_requires 'YAML::Syck';
test_requires 'Path::Class';
test_requires 'Exporter';
test_requires 'FindBin';

auto_install;
WriteAll;
