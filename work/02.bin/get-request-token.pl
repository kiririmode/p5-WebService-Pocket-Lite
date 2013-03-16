#!/usr/bin/env perl
use strict;
use warnings;
use LWP::UserAgent;
use YAML qw(LoadFile);
use FindBin qw/$Bin/;
use Path::Class;
use Log::Minimal;
use HTTP::Body;

$Log::Minimal::COLOR = 1;

my $REQUEST_URL = 'https://getpocket.com/v3/oauth/request';
my $agent = LWP::UserAgent->new;

my $file = file($Bin)->parent->subdir('01.info')->file('app-info.yaml');
my $conf  = LoadFile($file);
my $consumer_key = $conf->{'ConsumerKey'};

debugf("sending request with consumer key: $consumer_key");
my $res = $agent->post(
    $REQUEST_URL, {
	consumer_key => $consumer_key,
	redirect_uri => 'http://www.google.com',
	state        => ''
    }
);

debugf("http statusline: [", $res->status_line, "]");
if ( $res->is_success ) {
    my $content = $res->content;
    my $body    = HTTP::Body->new( $res->header('Content-Type'), $res->header('Content-Length') );
    $body->add($content);

    my $request_token = $body->param->{'code'};
    print "https://getpocket.com/auth/authorize?request_token=$request_token&redirect_uri=http://www.google.com\n"
}
else {
    croakf "failed. " . $res->status_line;
}
