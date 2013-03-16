use inc::Module::Install;
name 'WebService-Pocket-Lite';
all_from 'lib/WebService/Pocket/Lite.pm';

requires 'Class::Accessor::Lite';
requires 'Carp';
requires 'JSON';
requires 'LWP::UserAgent';
requires 'URI::Escape';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::LWP::UserAgent';
test_requires 'Sub::Uplevel';  # Test::Exception requires ?
test_requires 'Try::Tiny';     # Test::LWP::UserAgent requires ?
test_requires 'Safe::Isa';     # Test::LWP::UserAgent requires ?

auto_set_repository;
auto_include;
WriteAll;
