use strict;
use Test::More;
use WebService::Pocket::Lite;
use Test::LWP::UserAgent;
use Test::Exception;

Test::LWP::UserAgent->map_response(qr[getpocket.com/v3/oauth/authorize] => HTTP::Response->new( 200, 'OK', [], '{"access_token":"access_token","username":"pocketuser"}' ));
Test::LWP::UserAgent->map_response(qr[getpocket.com/v3/add]             => HTTP::Response->new( 200, 'OK', [], '{"item":{"item_id":"1"},"status":1}' ));
#{"item":{"item_id":"1","normal_url":"http:\\/\\/example.com","resolved_id":"18294","extended_item_id":"18294","resolved_url":"http:\\/\\/www.yahoo.co.jp\\/","domain_id":"49329","origin_domain_id":"49329","response_code":"200","mime_type":"text\\/html","content_length":"24916","encoding":"utf-8","date_resolved":"2013-03-15 05:44:50","date_published":"0000-00-00 00:00:00","title":"Yahoo! JAPAN","excerpt":"Yahoo! JAPAN\\u30c8\\u30c3\\u30d7\\u30da\\u30fc\\u30b8\\u306e\\u5168\\u6a5f\\u80fd\\u3092\\u3054\\u5229\\u7528\\u3044\\u305f\\u3060\\u304f\\u306b\\u306f\\u3001\\u4e0b\\u8a18\\u306e\\u74b0\\u5883\\u304c\\u5fc5\\u8981\\u3068\\u306a\\u308a\\u307e\\u3059\\u3002 Windows\\uff1aInternet Explorer 6.0\\u4ee5\\u4e0a \\/ Firefox 3.0\\u4ee5\\u4e0a\\u3000Macintosh\\uff1aSafari 3.","word_count":"18","innerdomain_redirect":"0","login_required":"0","has_image":"1","has_video":"0","is_index":"1","is_article":"0","used_fallback":"1","authors":[],"images":{"1":{"item_id":"18294","image_id":"1","src":"http:\\/\\/news.c.yimg.jp\\/images\\/topics\\/20130315-00000732-yom-000-thumb.jpg","width":"0","height":"0","credit":"","caption":""},"2":{"item_id":"18294","image_id":"2","src":"http:\\/\\/k.yimg.jp\\/images\\/premium\\/contents\\/bnr\\/2013\\/50x50\\/0311_dailyplus.png","width":"0","height":"0","credit":"","caption":""}},"videos":[],"resolved_normal_url":"http:\\/\\/yahoo.co.jp","given_url":"http:\\/\\/www.yahoo.co.jp"},"status":1}


my $ua = Test::LWP::UserAgent->new;
my $lite = WebService::Pocket::Lite->new( 
    ua             => $ua,
    consumer_key   => 'success',
    request_token  => 'success',
);

my $item_id;
lives_ok { $item_id = $lite->add({ url => 'foo' }) } '/add API';
is $item_id, 1;

done_testing;
