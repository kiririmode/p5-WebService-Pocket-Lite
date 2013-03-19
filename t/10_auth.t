use strict;
use Test::More;
use WebService::Pocket::Lite;
use Test::LWP::UserAgent;
use Test::Exception;

Test::LWP::UserAgent->map_response(
    qr[getpocket.com/v3/oauth/authorize] => sub {
        my $req = shift;

        if ( $req->content =~ /success/ ) {
            HTTP::Response->new( 200, 'OK', [], <<'AUTHORIZE' ),
{"access_token":"access_token",
"username":"pocketuser"}
AUTHORIZE
          }
        else {
            HTTP::Response->new( 400, 'ERROR', [
                'X-Error-Code' => 138,
                'X-Error'      => 'Missing consumer key.'
            ]);
        }
    }
);

my $ua = Test::LWP::UserAgent->new();
my $success_lite = WebService::Pocket::Lite->new( 
    ua             => $ua,
    consumer_key   => 'success',
    request_token  => 'success',
)->authorize;

is $success_lite->username, 'pocketuser';
is $success_lite->access_token, 'access_token';


my $failure_lite  = WebService::Pocket::Lite->new( 
    ua             => $ua,
    consumer_key   => 'failure',
    request_token  => 'failure',
);
throws_ok { $failure_lite->authorize; } qr/failed/, 'authentication error';

is $failure_lite->error, 'Missing consumer key.';
is $failure_lite->errorcode, 138;

done_testing;
