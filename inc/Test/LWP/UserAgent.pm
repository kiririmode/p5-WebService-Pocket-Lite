#line 1
package Test::LWP::UserAgent;
{
  $Test::LWP::UserAgent::VERSION = '0.015';
}
# git description: v0.014-14-g68d7af1

BEGIN {
  $Test::LWP::UserAgent::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: a LWP::UserAgent suitable for simulating and testing network calls

use strict;
use warnings;

use parent 'LWP::UserAgent';
use Scalar::Util qw(blessed reftype);
use Storable 'freeze';
use HTTP::Request;
use HTTP::Response;
use URI;
use HTTP::Date;
use HTTP::Status qw(:constants status_message);
use Try::Tiny;
use Safe::Isa;
use namespace::clean;

my @response_map;
my $network_fallback;
my $last_useragent;

sub __isa_coderef($);
sub __is_regexp($);

sub new
{
    my ($class, %options) = @_;

    my $_network_fallback = delete $options{network_fallback};

    my $self = $class->SUPER::new(%options);
    $self->{__last_http_request_sent} = undef;
    $self->{__last_http_response_received} = undef;
    $self->{__response_map} = [];
    $self->{__network_fallback} = $_network_fallback;

    # strips default User-Agent header added by LWP::UserAgent, to make it
    # easier to define literal HTTP::Requests to match against
    $self->agent(undef) if defined $self->agent and $self->agent eq $self->_agent;

    return $self;
}

sub map_response
{
    my ($self, $request_description, $response) = @_;

    if (not defined $response and blessed $self)
    {
        # mask a global domain mapping
        my $matched;
        foreach my $mapping (@{$self->{__response_map}})
        {
            if ($mapping->[0] eq $request_description)
            {
                $matched = 1;
                undef $mapping->[1];
            }
        }

        push @{$self->{__response_map}}, [ $request_description, undef ]
            if not $matched;

        return;
    }

    if (not $response->$_isa('HTTP::Response') and try { $response->can('request') })
    {
        my $oldres = $response;
        $response = sub {
            $oldres->request($_[0]) };
    }

    warn "map_response: response is not a coderef or an HTTP::Response, it's a ",
            (blessed($response) || 'non-object')
        unless __isa_coderef($response) or $response->$_isa('HTTP::Response');

    if (blessed $self)
    {
        push @{$self->{__response_map}}, [ $request_description, $response ];
    }
    else
    {
        push @response_map, [ $request_description, $response ];
    }
}

sub map_network_response
{
    my ($self, $request_description) = @_;

    if (blessed $self)
    {
        # we cannot call ::request here, or we end up in an infinite loop
        push @{$self->{__response_map}},
            [ $request_description, sub { $self->SUPER::send_request($_[0]) } ];
    }
    else
    {
        push @response_map,
            [ $request_description, sub { LWP::UserAgent->new->send_request($_[0]) } ];
    }
}

sub unmap_all
{
    my ($self, $instance_only) = @_;

    if (blessed $self)
    {
        $self->{__response_map} = [];
        @response_map = () unless $instance_only;
    }
    else
    {
        warn 'instance-only unmap requests make no sense when called globally'
            if $instance_only;
        @response_map = ();
    }
}

sub register_psgi
{
    my ($self, $domain, $app) = @_;

    return $self->map_response($domain, undef) if not defined $app;

    warn "register_psgi: app is not a coderef, it's a ", ref($app)
        unless __isa_coderef($app);

    warn "register_psgi: did you forget to load HTTP::Message::PSGI?"
        unless HTTP::Request->can('to_psgi') and HTTP::Response->can('from_psgi');

    return $self->map_response(
        $domain,
        sub { HTTP::Response->from_psgi($app->($_[0]->to_psgi)) },
    );
}

sub unregister_psgi
{
    my ($self, $domain, $instance_only) = @_;

    if (blessed $self)
    {
        @{$self->{__response_map}} = grep { $_->[0] ne $domain } @{$self->{__response_map}};

        @response_map = grep { $_->[0] ne $domain } @response_map
            unless $instance_only;
    }
    else
    {
        @response_map = grep { $_->[0] ne $domain } @response_map;
    }
}

sub last_http_request_sent
{
    my $self = shift;
    return blessed($self)
        ? $self->{__last_http_request_sent}
        : $last_useragent
            ? $last_useragent->last_http_request_sent
            : undef;
}

sub last_http_response_received
{
    my $self = shift;
    return blessed($self)
        ? $self->{__last_http_response_received}
        : $last_useragent
            ? $last_useragent->last_http_response_received
            : undef;
}

sub last_useragent
{
    return $last_useragent;
}

sub network_fallback
{
    my ($self, $value) = @_;

    if (@_ == 1)
    {
        return blessed $self
            ? $self->{__network_fallback}
            : $network_fallback;
    }

    return $self->{__network_fallback} = $value if blessed $self;
    $network_fallback = $value;
}

sub send_request
{
    my ($self, $request) = @_;

    $self->progress("begin", $request);
    my $matched_response = $self->run_handlers("request_send", $request);

    my $uri = $request->uri;

    foreach my $entry (@{$self->{__response_map}}, @response_map)
    {
        last if $matched_response;
        next if not defined $entry;
        my ($request_desc, $response) = @$entry;

        if ($request_desc->$_isa('HTTP::Request'))
        {
            $matched_response = $response, last
                if freeze($request) eq freeze($request_desc);
        }
        elsif (__is_regexp $request_desc)
        {
            $matched_response = $response, last
                if $uri =~ $request_desc;
        }
        elsif (__isa_coderef $request_desc)
        {
            $matched_response = $response, last
                if $request_desc->($request);
        }
        else
        {
            $uri = URI->new($uri) if not $uri->$_isa('URI');
            $matched_response = $response, last
                if $uri->host eq $request_desc;
        }
    }

    $last_useragent = $self;
    $self->{__last_http_request_sent} = $request;

    if (not defined $matched_response and
        ($self->{__network_fallback} or $network_fallback))
    {
        my $response = $self->SUPER::send_request($request);
        $self->{__last_http_response_received} = $response;
        return $response;
    }

    my $response = defined $matched_response
        ? $matched_response
        : HTTP::Response->new(404);

    if (__isa_coderef $response)
    {
        # emulates handling in LWP::UserAgent::send_request
        if ($self->use_eval)
        {
            $response = try { $response->($request) }
            catch {
                my $exception = $_;
                if ($exception->$_isa('HTTP::Response'))
                {
                    $response = $exception;
                }
                else
                {
                    my $full = $exception;
                    (my $status = $exception) =~ s/\n.*//s;
                    $status =~ s/ at .* line \d+.*//s;  # remove file/line number
                    my $code = ($status =~ s/^(\d\d\d)\s+//) ? $1 : HTTP_INTERNAL_SERVER_ERROR;
                    # note that _new_response did not always take a fourth
                    # parameter - content used to always be "$code $message"
                    $response = LWP::UserAgent::_new_response($request, $code, $status, $full);
                }
            }
        }
        else
        {
            $response = $response->($request);
        }
    }

    if (not $response->$_isa('HTTP::Response'))
    {
        warn "response from coderef is not a HTTP::Response, it's a ",
            (blessed($response) || 'non-object');
        $response = LWP::UserAgent::_new_response($request, HTTP_INTERNAL_SERVER_ERROR, status_message(HTTP_INTERNAL_SERVER_ERROR));
    }
    else
    {
        $response->request($request);  # record request for reference
        $response->header("Client-Date" => HTTP::Date::time2str(time));
    }

    $self->run_handlers("response_done", $response);
    $self->progress("end", $response);

    $self->{__last_http_response_received} = $response;

    return $response;
}

sub __isa_coderef($)
{
    ref $_[0] eq 'CODE'
        or (reftype($_[0]) || '') eq 'CODE'
        or overload::Method($_[0], '&{}')
}

sub __is_regexp($)
{
    $^V < 5.009005 ? ref(shift) eq 'Regexp' : re::is_regexp(shift);
}

1;

__END__

#line 716
