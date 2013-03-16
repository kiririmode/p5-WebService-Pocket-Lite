use strict;
use Test::More;
use WebService::Pocket::Lite;
use Test::LWP::UserAgent;
use Test::Exception;

Test::LWP::UserAgent->map_response(qr[getpocket.com/v3/get] => HTTP::Response->new( 200, 'OK', [], <<'GET'));
{"status":1,"list":{"229279689":{"item_id":"229279689",
"resolved_id":"229279689",
"given_url":"http:\/\/www.grantland.com\/blog\/the-triangle\/post\/_\/id\/38347\/ryder-cup-preview",
"given_title":"The Massive Ryder Cup Preview - The Triangle Blog - Grantland",
"favorite":"0",
"status":"0",
"resolved_title":"The Massive Ryder Cup Preview",
"resolved_url":"http:\/\/www.grantland.com\/blog\/the-triangle\/post\/_\/id\/38347\/ryder-cup-preview",
"excerpt":"The list of things I love about the Ryder Cup is so long that it could fill a (tedious) novel, and golf fans can probably guess most of them.",
"is_article":"1",
"has_video":"1",
"has_image":"1",
"word_count":"3197",
"images":{"1":{"item_id":"229279689","image_id":"1",
	"src":"http:\/\/a.espncdn.com\/combiner\/i?img=\/photo\/2012\/0927\/grant_g_ryder_cr_640.jpg&w=640&h=360",
	"width":"0","height":"0","credit":"Jamie Squire\/Getty Images","caption":""}},
"videos":{"1":{"item_id":"229279689","video_id":"1",
	"src":"http:\/\/www.youtube.com\/v\/Er34PbFkVGk?version=3&hl=en_US&rel=0",
	"width":"420","height":"315","type":"1","vid":"Er34PbFkVGk"}}}}}
GET

my $ua = Test::LWP::UserAgent->new;
my $lite = WebService::Pocket::Lite->new( 
    ua             => $ua,
    consumer_key   => 'success',
    request_token  => 'success',
);

my $res;
lives_ok { $res = $lite->retrieve({ tag => 'test1' }) };

done_testing;
