use strict;
use Test::More tests => 3;
use WebService::Pocket::Lite;


my $lite = WebService::Pocket::Lite->new(
    consumer_key  => 'aaa',
    request_token => 'bbb',
    access_token  => 'ccc',
);

is $lite->consumer_key, 'aaa';
is $lite->request_token, 'bbb';
is $lite->access_token, 'ccc';
