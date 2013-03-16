use strict;
use Test::More;
use WebService::Pocket::Lite;

is_deeply WebService::Pocket::Lite::_replace_tags( {
    tags => [ qw/a b c/ ],
    foo => 'var',
    hoge => {
	fuga => 'FUGA',
	tags => [ qw/d e f/ ],
    }
}), 
{
    tags => 'a,b,c',
    foo => 'var',
    hoge => {
	fuga => 'FUGA',
	tags => 'd,e,f'
    }
};

done_testing;
