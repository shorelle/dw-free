#!/usr/bin/perl
##############################################################################

=head1 NAME

LJ::Test::Result - Unit-test result class for LiveJournal testing

=head1 SYNOPSIS

  use LJ::Test::Result qw{};
  use LJ::Test::Assertions qw{:all};

  my $res = new LJ::Test::Result;
  $res->run( sub {assert(1)} );

  print "Results: ", $res->stringify, "\n\n";

=head1 REQUIRES

C<Danga::Exceptions>, C<LJ::Object>, C<LJ::Test::Assertions>, C<LJ::Test::Unit>

=head1 DESCRIPTION

None yet.

=head1 AUTHOR

Michael Granger E<lt>ged@danga.comE<gt>

Copyright (c) 2004 Danga Interactive. All rights reserved.

This module is free software. You may use, modify, and/or redistribute this
software under the terms of the Perl Artistic License. (See
http://language.perl.com/misc/Artistic.html)

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

=cut

##############################################################################
package LJ::Test::Result;
use strict;
use warnings qw{all};


###############################################################################
###  I N I T I A L I Z A T I O N
###############################################################################
BEGIN {
    ### Versioning stuff and custom includes
    use vars qw{$VERSION $RCSID};
    $VERSION    = do { my @r = (q$Revision: 4628 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
    $RCSID  = q$Id: Result.pm 4628 2004-10-30 02:07:22Z deveiant $;

    use LJ::Test::Unit          qw{};
    use LJ::Test::Assertions    qw{};
    use Danga::Exceptions       qw{:syntax};

    use LJ::Object ({
        assertions      => 0,
        passed          => 0,
        runs            => [],
        failures        => [],
        errors          => [],
    });

    use base qw{LJ::Object};
}




###############################################################################
### C O N S T R U C T O R
###############################################################################


sub new {
    my $class = shift;

    my $self = $class->SUPER::new( @_ );

    $self->assertions( 0 );
    $self->passed( 0 );
    $self->runs( [] );
    $self->failures( [] );
    $self->errors( [] );

    return $self;
}



### METHOD: run( \&coderef )
### Run a test I<coderef>, counting assertions, errors, and failures towards the
### result.
sub run ($&) {
    my ( $self, $testcode ) = @_;
    my $rchar = '.';

    try {
        $self->pushRuns( "$testcode" );
        LJ::Test::Assertions->add_observer( $self );
        $testcode->();
    } catch LJ::Test::AssertionFailure with {
        my ( $failure, $keeptrying ) = @_;
        $self->pushFailures( $failure );
        $$keeptrying = 0;
        $rchar = 'F';
    } catch Danga::Exception with {
        my $error = shift;
        $self->pushErrors( $error );
        $rchar = 'E';
    } finally {
        LJ::Test::Assertions->remove_observer( $self );
    };

    return $rchar;
}


### METHOD: update( $package, $type )
### Observable callback: Called from LJ::Test::Assertion when an assertion is
### made or passes.
sub update {
    my $self = shift or throw Danga::MethodError;
    my ( $package, $type ) = @_;

    if ( $type eq 'assert' ) {
        $self->{assertions}++;
    }

    elsif ( $type eq 'success' ) {
        $self->{passed}++;
    }

    else {
        warn "Unhandled update type '$type' from '$package'";
    }
}


### METHOD: stringify()
### Return a string representation of the test results as a scalar.
sub stringify {
    my $self = shift or throw Danga::MethodError;

    my @rval = ("");
    my @exceptions;

    # Add any error traces that occurred
    if (( @exceptions = $self->errors )) {
        push @rval, "Errors:";
        foreach my $exception ( @exceptions ) {
            push @rval, $exception->stringify;
        }
    }

    # Add any assertion failure messages
    if (( @exceptions = $self->failures )) {
        push @rval, "Failures:";
        foreach my $failure ( @exceptions ) {
            push @rval, $failure->error;
        }
    }

    # Now append the totals
    push @rval, sprintf( "%d tests, %d assertions, %d failures, %d errors",
                         scalar @{$self->{runs}},
                         $self->{assertions},
                         scalar @{$self->{failures}},
                         scalar @{$self->{errors}} );

    return join( "\n", @rval );
}



1;


###	AUTOGENERATED DOCUMENTATION FOLLOWS

=head1 METHODS

=over 4

=item I<run( \&coderef )>

Run a test I<coderef>, counting assertions, errors, and failures towards the
result.

=item I<stringify()>

Return a string representation of the test results as a scalar.

=item I<update( $package, $type )>

Observable callback: Called from LJ::Test::Assertion when an assertion is
made or passes.

=back

=cut

