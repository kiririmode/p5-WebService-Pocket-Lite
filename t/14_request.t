use strict;
use Test::More;
use WebService::Pocket::Lite;
use Test::LWP::UserAgent;
use Test::Exception;

Test::LWP::UserAgent->map_response(
    qr[getpocket.com/v3/oauth/request] => 
      HTTP::Response->new( 200, 'OK', [], '{"code":"dcba4321-dcba-4321-dcba-4321dc"}')
);

my $lite = WebService::Pocket::Lite->new( 
    ua             => Test::LWP::UserAgent->new,
    consumer_key   => 'key1',
);

lives_ok { $lite->retrieve_request_token({ redirect_url => 'http://example.com' })}, 'request_token';
is $lite->request_token, 'dcba4321-dcba-4321-dcba-4321dc';

done_testing;
