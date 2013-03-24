use strict;
use Test::More tests => 6;
use WebService::Pocket::Lite;
use Test::Exception;

lives_ok  { WebService::Pocket::Lite::_param_check({ foo => 1 }, {foo => 'FOO'} ) }, 'mandatory parameter';
lives_ok  { WebService::Pocket::Lite::_param_check({ foo => 0 }, {foo => 'FOO'} ) }, 'optional parameter';
throws_ok { WebService::Pocket::Lite::_param_check({ foo => 1 }, {bar => 'BAR'} ) } qr/missing/, 'missing';
throws_ok { WebService::Pocket::Lite::_param_check({ foo => 1 }, {foo => 'FOO', bar => 'BAR'} ) } qr/not listed/, 'not listed';

throws_ok { WebService::Pocket::Lite::_param_check({ foo => 1 })     } qr/must be HASH ref/, 'no $arg';
throws_ok { WebService::Pocket::Lite::_param_check({ foo => 1 }), [] } qr/must be HASH ref/, 'not HASH ref';
