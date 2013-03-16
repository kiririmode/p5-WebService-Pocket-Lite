use inc::Module::Install;
name 'WebService-Pocket-Lite';
all_from 'lib/WebService/Pocket/Lite.pm';

requires 'Class::Accessor::Lite';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::LWP::UserAgent';

auto_set_repository;
auto_include;
WriteAll;
