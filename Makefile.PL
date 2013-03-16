use inc::Module::Install;
name 'WebService-Pocket-Lite';
all_from 'lib/WebService/Pocket/Lite.pm';

requires 'Class::Accessor::Lite' => '0';
requires 'Carp'                  => '0';
requires 'JSON'                  => '0';
requires 'LWP::UserAgent'        => '0';
requires 'URI::Escape'           => '0';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More'            => '0';
test_requires 'Test::Exception'       => '0';
test_requires 'Test::LWP::UserAgent'  => '0';
test_requires 'Sub::Uplevel'          => '0'; # Test::Exception requires ?
test_requires 'Try::Tiny'             => '0'; # Test::LWP::UserAgent requires ?
test_requires 'Safe::Isa'             => '0'; # Test::LWP::UserAgent requires ?
test_requires 'namespace::clean'      => '0'; # Test::LWP::UserAgent requires ?

auto_set_repository;
auto_include;
WriteAll;
