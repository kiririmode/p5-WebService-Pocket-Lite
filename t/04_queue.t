use strict;
use Test::More;
use WebService::Pocket::Lite;
use Test::LWP::UserAgent;

Test::LWP::UserAgent->map_response(qr[getpocket.com/v3/send] => HTTP::Response->new( 200, 'OK', [], '{"action_results":[],"status":1}' ));

my $ua = Test::LWP::UserAgent->new;
my $lite = WebService::Pocket::Lite->new(
    consumer_key  => 'aaa',
    request_token => 'bbb',
    access_token  => 'ccc',
    ua            => $ua,
);

is scalar(@{$lite->queue}), 0, 'empty queue';

$lite->push_add({ url => 'http://www.google.com' });

is scalar(@{$lite->queue}), 1, '1 elem added';
is_deeply( $lite->queue, [{ action => 'add', url => 'http://www.google.com' }]);

$lite->send;

is scalar(@{$lite->queue}), 0;

done_testing;
