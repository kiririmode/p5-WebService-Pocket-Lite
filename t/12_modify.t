use strict;
use Test::More;
use WebService::Pocket::Lite;
use Test::LWP::UserAgent;
use Test::Exception;

Test::LWP::UserAgent->map_response(qr[getpocket.com/v3/send] => HTTP::Response->new( 200, 'OK', [], '{"action_results":[],"status":1}' ));

my $ua = Test::LWP::UserAgent->new;
my $lite = WebService::Pocket::Lite->new( 
    ua             => $ua,
    consumer_key   => 'success',
    request_token  => 'success',
);

my $item_id;

$lite->push_add({ url => 'test1' });
$lite->push_add({ url => 'test2' });

my $status;
lives_ok { $status = $lite->send() } '/send API';
is $status, 1;

done_testing;
