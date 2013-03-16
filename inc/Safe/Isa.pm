#line 1
package Safe::Isa;

use strict;
use warnings FATAL => 'all';
use Scalar::Util qw(blessed);
use base qw(Exporter);

our $VERSION = '1.000002';

our @EXPORT = qw($_call_if_object $_isa $_can $_does $_DOES);

our $_call_if_object = sub {
  my ($obj, $method) = (shift, shift);
  return unless blessed($obj);
  return $obj->$method(@_);
};

our ($_isa, $_can, $_does, $_DOES) = map {
  my $method = $_;
  sub { my $obj = shift; $obj->$_call_if_object($method => @_) }
} qw(isa can does DOES);

#line 166
