package WebService::Pocket::Lite;
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use URI::Escape;
use Class::Accessor::Lite (
    ro => [ qw/request_token consumer_key access_token/ ],
    rw => [ qw/username access_token queue errorcode error user_limit user_remaining user_reset key_limit key_remaining key_reset/ ],
);

our $VERSION = '0.01';

my $POCKET_URL = 'https://getpocket.com/v3';
my %ratelimit_header_map = (
    'X-Limit-User-Limit'     => 'user_limit',
    'X-Limit-User-Remaining' => 'user_remaining',
    'X-Limit-User-Reset'     => 'user_reset',
    'X-Limit-Key-Limit:'     => 'key_limit',
    'X-Limit-Key-Remaining'  => 'key_remaining',
    'X-Limit-Key-Reset'	     => 'key_reset'
);

my @modify_api_sets = (
    [ 'push_add',         'add',          { item_id => 0, ref_id => 0, tags => 0, time => 0, title => 0, url => 1 } ],
    [ 'push_modify',      'add',          { item_id => 1, ref_id => 0, tags => 0, time => 0, title => 0, url => 0 } ],
    [ 'push_archive',     'archive',      { item_id => 1, time => 0, } ],
    [ 'push_unarchive',	  'readd',        { item_id => 1, time => 0, } ],
    [ 'push_favorite',	  'favorite',     { item_id => 1, time => 0, } ],
    [ 'push_unfavorite',  'unfavorite',   { item_id => 1, time => 0, } ],
    [ 'push_delete',	  'delete',       { item_id => 1, time => 0, } ],
    [ 'push_tags_add',	  'tags_add',     { item_id => 1, tags => 1, time => 0 } ],
    [ 'push_tags_remove', 'tags_remove',  { item_id => 1, tags => 1, time => 0 } ],
    [ 'push_tags_replace','tags_replace', { item_id => 1, tags => 1, time => 0 } ],
    [ 'push_tags_clear',  'tags_clear',   { item_id => 1, time => 0 } ],
    [ 'push_tag_rename',  'tag_rename',   { itme_id => 1, old_tag => 1, new_tag => 1, time => 0 } ],
);

{
    no strict 'refs';
    foreach my $set (@modify_api_sets) {
	my $method = __PACKAGE__ . '::' . $set->[0];
        *{$method} = sub {
	    my ($self, $param) = @_;
	    $self->_push( $set->[1], $param, $set->[2] );
	}
    }
}

sub new {
    my ($class, %arg) = @_;

    bless {
	ua            => $arg{ua} || LWP::UserAgent->new,
	consumer_key  => $arg{consumer_key},
	request_token => $arg{request_token},
	access_token  => $arg{access_token},
	queue         => [],
    }, $class;
}

sub _post {
    my ($self, $path, $param) = @_;

    _replace_tags($param);

    my $res = $self->{ua}->post(
	"$POCKET_URL$path", 
	# headers
	'Content-Type'  => 'application/json; charset=UTF-8',
	# body
	Content => to_json($param),
    );

    foreach my $header (keys %ratelimit_header_map) {
	my $methodname = $ratelimit_header_map{$header};
	my $val = $res->header($header);

	$self->$methodname( $val ) if defined $val;
    }

    if ( not $res->is_success ) {

	$self->errorcode( $res->header('X-Error-Code') );
	$self->error( $res->header('X-Error') );

	my $caller = (caller(1))[3];
	die "$caller failed.  Pocket says [", $self->error, "] ,", $res->status_line, "]";
    }

    from_json $res->decoded_content;
}

sub _replace_tags {
    my $h = shift;

    die "tags must be an HASH ref" unless ref($h) eq 'HASH';

    foreach my $k (keys %$h) {
	if ( ref($h->{$k}) eq 'HASH' ) {
	    _replace_tags($h->{$k});
	}

	if ( $k eq 'tags' ) {
	    $h->{$k} = join "," => @{$h->{$k}};
	}
    }

    $h;
}

sub authorize {
    my ($self) = @_;

    my $res = $self->_post('/oauth/authorize', {
	consumer_key => $self->consumer_key,
	code         => $self->request_token,
    });

    $self->username( $res->{username} );
    $self->access_token( $res->{access_token} );

    $self;
}

sub add {
    my ($self, $arg) = @_;
    _param_check({ url => 1, title => 0, tags => 0, tweet_id => 0 }, $arg);

    my $res = $self->_post('/add', {
	%$arg,
	consumer_key => $self->consumer_key,
	access_token => $self->access_token,
    });

    $res->{item}->{item_id};
}

sub retrieve {
    my ($self, $arg) = @_;
    _param_check({ state => 0, favorite => 0, tag => 0, contentType => 0, sort => 0,
		   detailType => 0, search => 0, domain => 0, since => 0, count => 0, offset => 0 });

    my $res => $self->_post('/get', {
	%$arg,
	consumer_key => $self->consumer_key,
	access_token => $self->access_token,
    });
}

sub send {
    my ($self) = @_;

    my $res = $self->_post('/send', {
	actions      => $self->queue,
	consumer_key => $self->consumer_key,
	access_token => $self->access_token,
    });

    # clear queued actions.
    $self->queue([]);

    $res->{status};
}

sub _push {
    my ($self, $action, $param, $paramcheck) = @_;

    _param_check( $paramcheck, $param );
    push $self->queue, {
	action => $action,
	%$param,
    };
}

sub _param_check {
    my ($rule, $arg) = @_;

    my %rule = %$rule;

    # mandatory check
    map { ( $rule->{$_} and not $arg->{$_})? die "parameter $_ is missing." : ()   } keys %rule;

    # not listed parameter
    map { (not defined $rule->{$_})? die "$_ is not listed parameter." : ()      } keys %$arg;
};

1;
__END__

=head1 NAME

WebService::Pocket::Lite - Pocket Client for Perl

=head1 SYNOPSIS

  use WebService::Pocket::Lite;

  my $lite = WebService::Pocket::Lite->new(
    access_token => 'your access token',
    consumer_key => 'consumer key',
  );

  # retrieve entries from your Pocket.
  my $res = $lite->retrieve( state => 'unread', tag => 'perl' );

  # add a entry to your Pocket.
  $lite->add( url => 'http://www.cpan.org' );

  # add some entries and change tags of another entry with 1 req.
  $lite->push_add( url => 'http://metacpan.org/' );
  $lite->push_add( url => 'http://cpants.cpanauthors.org/' );
  $lite->push_tags_replace( item_id => 100, tags => [qw/tag1 tag2/] );
  $lite->send;

=head1 DESCRIPTION

WebService::Pocket::Lite is a Perl client for Pocket (formerly Read it Later).

=head1 AUTHOR

kiririmode E<lt>kiririmode@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
