#line 1
package namespace::clean;

use warnings;
use strict;

use Package::Stash;

our $VERSION = '0.24';
our $STORAGE_VAR = '__NAMESPACE_CLEAN_STORAGE';

use B::Hooks::EndOfScope 'on_scope_end';

#line 143

# Constant to optimise away the unused code branches
use constant FIXUP_NEEDED => $] < 5.015_005_1;
use constant FIXUP_RENAME_SUB => $] > 5.008_008_9 && $] < 5.013_005_1;
{
  no strict;
  delete ${__PACKAGE__."::"}{FIXUP_NEEDED};
  delete ${__PACKAGE__."::"}{FIXUP_RENAME_SUB};
}

# Debugger fixup necessary before perl 5.15.5
#
# In perl 5.8.9-5.12, it assumes that sub_fullname($sub) can
# always be used to find the CV again.
# In perl 5.8.8 and 5.14, it assumes that the name of the glob
# passed to entersub can be used to find the CV.
# since we are deleting the glob where the subroutine was originally
# defined, those assumptions no longer hold.
#
# So in 5.8.9-5.12 we need to move it elsewhere and point the
# CV's name to the new glob.
#
# In 5.8.8 and 5.14 we move it elsewhere and rename the
# original glob by assigning the new glob back to it.
my $sub_utils_loaded;
my $DebuggerFixup = sub {
  my ($f, $sub, $cleanee_stash, $deleted_stash) = @_;

  if (FIXUP_RENAME_SUB) {
    if (! defined $sub_utils_loaded ) {
      $sub_utils_loaded = do {

        # when changing version also change in Makefile.PL
        my $sn_ver = 0.04;
        eval { require Sub::Name; Sub::Name->VERSION($sn_ver) }
          or die "Sub::Name $sn_ver required when running under -d or equivalent: $@";

        # when changing version also change in Makefile.PL
        my $si_ver = 0.04;
        eval { require Sub::Identify; Sub::Identify->VERSION($si_ver) }
          or die "Sub::Identify $si_ver required when running under -d or equivalent: $@";

        1;
      } ? 1 : 0;
    }

    if ( Sub::Identify::sub_fullname($sub) eq ($cleanee_stash->name . "::$f") ) {
      my $new_fq = $deleted_stash->name . "::$f";
      Sub::Name::subname($new_fq, $sub);
      $deleted_stash->add_symbol("&$f", $sub);
    }
  }
  else {
    $deleted_stash->add_symbol("&$f", $sub);
  }
};

my $RemoveSubs = sub {
    my $cleanee = shift;
    my $store   = shift;
    my $cleanee_stash = Package::Stash->new($cleanee);
    my $deleted_stash;

  SYMBOL:
    for my $f (@_) {

        # ignore already removed symbols
        next SYMBOL if $store->{exclude}{ $f };

        my $sub = $cleanee_stash->get_symbol("&$f")
          or next SYMBOL;

        my $need_debugger_fixup =
          FIXUP_NEEDED
            &&
          $^P
            &&
          ref(my $globref = \$cleanee_stash->namespace->{$f}) eq 'GLOB'
        ;

        if (FIXUP_NEEDED && $need_debugger_fixup) {
          # convince the Perl debugger to work
          # see the comment on top of $DebuggerFixup
          $DebuggerFixup->(
            $f,
            $sub,
            $cleanee_stash,
            $deleted_stash ||= Package::Stash->new("namespace::clean::deleted::$cleanee"),
          );
        }

        my @symbols = map {
            my $name = $_ . $f;
            my $def = $cleanee_stash->get_symbol($name);
            defined($def) ? [$name, $def] : ()
        } '$', '@', '%', '';

        $cleanee_stash->remove_glob($f);

        # if this perl needs no renaming trick we need to
        # rename the original glob after the fact
        # (see commend of $DebuggerFixup
        if (FIXUP_NEEDED && !FIXUP_RENAME_SUB && $need_debugger_fixup) {
          *$globref = $deleted_stash->namespace->{$f};
        }

        $cleanee_stash->add_symbol(@$_) for @symbols;
    }
};

sub clean_subroutines {
    my ($nc, $cleanee, @subs) = @_;
    $RemoveSubs->($cleanee, {}, @subs);
}

#line 264

sub import {
    my ($pragma, @args) = @_;

    my (%args, $is_explicit);

  ARG:
    while (@args) {

        if ($args[0] =~ /^\-/) {
            my $key = shift @args;
            my $value = shift @args;
            $args{ $key } = $value;
        }
        else {
            $is_explicit++;
            last ARG;
        }
    }

    my $cleanee = exists $args{ -cleanee } ? $args{ -cleanee } : scalar caller;
    if ($is_explicit) {
        on_scope_end {
            $RemoveSubs->($cleanee, {}, @args);
        };
    }
    else {

        # calling class, all current functions and our storage
        my $functions = $pragma->get_functions($cleanee);
        my $store     = $pragma->get_class_store($cleanee);
        my $stash     = Package::Stash->new($cleanee);

        # except parameter can be array ref or single value
        my %except = map {( $_ => 1 )} (
            $args{ -except }
            ? ( ref $args{ -except } eq 'ARRAY' ? @{ $args{ -except } } : $args{ -except } )
            : ()
        );

        # register symbols for removal, if they have a CODE entry
        for my $f (keys %$functions) {
            next if     $except{ $f };
            next unless $stash->has_symbol("&$f");
            $store->{remove}{ $f } = 1;
        }

        # register EOF handler on first call to import
        unless ($store->{handler_is_installed}) {
            on_scope_end {
                $RemoveSubs->($cleanee, $store, keys %{ $store->{remove} });
            };
            $store->{handler_is_installed} = 1;
        }

        return 1;
    }
}

#line 332

sub unimport {
    my ($pragma, %args) = @_;

    # the calling class, the current functions and our storage
    my $cleanee   = exists $args{ -cleanee } ? $args{ -cleanee } : scalar caller;
    my $functions = $pragma->get_functions($cleanee);
    my $store     = $pragma->get_class_store($cleanee);

    # register all unknown previous functions as excluded
    for my $f (keys %$functions) {
        next if $store->{remove}{ $f }
             or $store->{exclude}{ $f };
        $store->{exclude}{ $f } = 1;
    }

    return 1;
}

#line 357

sub get_class_store {
    my ($pragma, $class) = @_;
    my $stash = Package::Stash->new($class);
    my $var = "%$STORAGE_VAR";
    $stash->add_symbol($var, {})
        unless $stash->has_symbol($var);
    return $stash->get_symbol($var);
}

#line 374

sub get_functions {
    my ($pragma, $class) = @_;

    my $stash = Package::Stash->new($class);
    return {
        map { $_ => $stash->get_symbol("&$_") }
            $stash->list_all_symbols('CODE')
    };
}

#line 443

no warnings;
'Danger! Laws of Thermodynamics may not apply.'
