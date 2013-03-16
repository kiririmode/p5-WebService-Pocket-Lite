use strict;
use Test::More;
use WebService::Pocket::Lite;


my $lite = WebService::Pocket::Lite->new(
    consumer_key  => 'aaa',
    request_token => 'bbb',
    access_token  => 'ccc',
);

is $lite->consumer_key, 'aaa';
is $lite->request_token, 'bbb';
is $lite->access_token, 'ccc';

done_testing;
