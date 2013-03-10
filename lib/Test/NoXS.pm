use strict;
use warnings;
package Test::NoXS;
# ABSTRACT: Prevent a module from loading its XS code
our $VERSION = '1.02'; # VERSION

my @no_xs_modules;
my $no_xs_all;

sub import {
    my $class = shift;
    if  ( grep { /:all/ } @_ ) {
      $no_xs_all = 1;
    }
    else {
      push @no_xs_modules, @_;
    }
}

# Overload DynaLoader and XSLoader to fake lack of XS for designated modules
{
    no strict 'refs';
    no warnings 'redefine';
    local $^W;
    require DynaLoader;
    my $bootstrap_orig = *{"DynaLoader::bootstrap"}{CODE};
    *DynaLoader::bootstrap = sub {
        my $caller = @_ ? $_[0] : caller;
        die "XS disabled" if $no_xs_all;
        die "XS disable for $caller" if grep { $caller eq $_ } @no_xs_modules;
        goto $bootstrap_orig;
    };
    # XSLoader entered Core in Perl 5.6
    if ( $] >= 5.006 ) {
        require XSLoader;
        my $xsload_orig = *{"XSLoader::load"}{CODE};
        *XSLoader::load = sub {
            my $caller = @_ ? $_[0] : caller;
            die "XS disabled" if $no_xs_all;
            die "XS disable for $caller" if grep { $caller eq $_ } @no_xs_modules;
            goto $xsload_orig;
        };
    }
}


1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=head1 NAME

Test::NoXS - Prevent a module from loading its XS code

=head1 VERSION

version 1.02

=head1 SYNOPSIS

    use Test::NoXS 'Class::Load::XS';
    use Module::Implementation;

    eval "use Class::Load";
    is(
        Module::Implementation::implementation_for("Class::Load"),
        "PP",
        "Class::Load using PP"
    );

    # Disable all XS loading
    use Test::NoXS ':all';

=head1 DESCRIPTION

This modules hijacks L<DynaLoader> and L<XSLoader> to prevent them from loading
XS code for designated modules.  This is intended to help test how modules
react to missing XS, e.g. by dying with a message or by falling back to a
pure-Perl alternative.

=head1 USAGE

Modules that should not load XS should be given as a list of arguments to C<use
Test::NoXS>.  Alternatively, giving ':all' as an argument will disable all
future attempts to load XS.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/test-noxs/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/test-noxs>

  git clone git://github.com/dagolden/test-noxs.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
