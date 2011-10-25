package Text::sprintfn;

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(sprintfn printfn);

my  $re1   = qr/[^)]+/s;
our $regex = qr{(?<fmt>
                    %
                       (?: (?<dpi>\d+)\$ | \((?<npi>$re1)\)\$?)?
                       (?<flags>[ +0#-]*)
                       (?<vflag>(?<wvflag>\*?)[v]?)
                       (?: (?<dwidth>-?\d+) |
                           (?<wwidth>\*?)(?:(?<wwidthd>\d+)\$)? |
                           \((?<nwidth>$re1)\))?
                       (?: \.
                           (?: (?<dprec>\d+) | (?<wprec>\*) |
                           \((?<nprec>$re1)\) ) )?
                       (?<conv> [%csduoxefgXEGbBpniDUOF])
             )}x;

sub sprintfn {
    my ($format, @args) = @_;

    my $hash;
    if (ref($args[0]) eq 'HASH') {
        $hash = shift(@args);
        splice @_, 1, 1; # remove hash arg so it doesn't interfere with %2$d
    }
    return sprintf($format, @args) if !$hash;

    # we use sprintf() for each format, we convert the named parameters and
    # handle the * and \d+$ stuffs ourselves.

    my ($shift, $pi, $flags, $vflag, $width, $prec, $conv, $fmt, $res);
    $format =~ s{$regex}{
        # careful not to use any regex here
        $shift = 0;
        my $w_in_vflag;

        $flags = $+{flags};

        if ($+{wvflag}) {
            $vflag = $+{vflag};
            unshift @args, $args[0];
            $shift += 2;
            $w_in_vflag++;
        } elsif ($+{vflag}) {
            $vflag = $+{vflag};
        } else {
            $vflag = "";
        }

        if (defined $+{dwidth}) {
            $width = $+{dwidth};
        } elsif ($+{wwidth}) {
            if (defined $+{wwidthd}) {
                $width = int($_[ $+{wwidthd} ]);
            } else {
                $width = int(shift(@args));
            }
        } elsif (defined $+{nwidth}) {
            $width = int($hash->{ $+{nwidth} });
        } else {
            $width = "";
        }

        if (defined $+{dprec}) {
            $prec = ".$+{dprec}";
        } elsif ($+{wprec}) {
            $prec = "." . int(shift @args);
        } elsif (defined $+{nprec}) {
            $prec = "." . int($hash->{ $+{nprec} });
        } else {
            $prec = "";
        }

        if (defined $+{dpi}) {
            if ($w_in_vflag) {
                $pi = q[2$];
                splice @args, 1, 0, $_[ $+{dpi} ];
            } else {
                $pi = q[1$];
                unshift @args, $_[ $+{dpi} ];
            }
        } elsif (defined $+{npi}) {
            if ($w_in_vflag) {
                $pi = q[2$];
                splice @args, 1, 0, $hash->{ $+{npi} };
            } else {
                $pi = q[1$];
                unshift @args, $hash->{ $+{npi} };
            }
        } else {
            $pi = "";
        }

        $conv = $+{conv};

        $fmt = "%$pi$flags$vflag$width$prec$conv";
        $res = sprintf($fmt, @args);

        # DEBUG
        #my %a = %+; print "\%+={".join(", ", %a)."} \n";
        #print "\@args=(".join(", ", @args).") \n";
        #print "[DBG:pi=<$pi> flags=<$flags> vflag=<$vflag> width=<$width> ".
        #    "prec=<$prec> conv=<$conv> fmt=<$fmt> ".
        #        "args=(".join(",",@args).") res=<$res>]\n";

        $shift++;
        shift @args for $shift;
        $res;
    }xeg;
    $format;
}

sub printfn {
    print sprintfn @_;
}

1;
# ABSTRACT: Drop-in replacement for sprintf(), with named parameter support



__END__
=pod

=head1 NAME

Text::sprintfn - Drop-in replacement for sprintf(), with named parameter support

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Text::sprintfn; # by default exports sprintfn() and printfn()

 printfn("<%2d> <%(foo)-(bar).2f> <%0$04d>", {foo=>1, bar=>5}, 3, 42);
 # < 3> <1.00 > <0003>

 print sprintf "<%-4d>", 123; # no hash provided, acts like normal sprintf()
 # <123 >

=head1 DESCRIPTION

This module provides sprintfn() and printfn(), which are like sprintf() and
printf(), with the exception that they support named parameters from a hash.

There exist other CPAN modules for string formatting with named parameter
support, but this one focuses on interface simplicity and sprintf compatibility
since most people are already familiar with it and it has several features.

=head1 FUNCTIONS

=head2 sprintfn FORMAT, HASH_ARG, OTHER_ARG, ...

If first argument after format is not a hash, sprintfn() will behave exactly
like sprintf().

If HASH_ARG is given, sprintfn() will look for named parameters in argument and
supply the values from the hash. Named parameters are surrounded with
parentheses, i.e. "(NAME)". They can occur in format parameter index:

 %2$d        # sprintf version, take argument at index 2
 %(two)d     # $ is optional
 %(two)$d    # same

or in width:

 %-10d       # sprintf version, use (minimum) width of 10
 %-(width)d  # like sprintf, but use width from hash key 'width'
 %(var)-(width)d  # format hash key 'var' with width from hash key 'width'

or in precision:

 %6.2f       # sprintf version, use precision of 2 decimals
 %6.(prec)f  # like sprintf, but use precision from hash key 'prec'
 %(width).(prec)f
 %(var)(width).(prec)f

The existence of formats using hash keys will not affect indexes of the rest of
the argument, example:

 sprintfn "<%(v1)s> <%2$d> <%d>", {v1=>10}, 0, 1, 2; # "<10> <2> <0>"

Like sprintf(), if format is unknown/erroneous, it will be printed as-is.

There is currently no way to escape ")" in named parameter, e.g.:

 %(var containing ))s

=head2 printfn

Equivalent to "print sprintf(@_)".

=head1 TIPS AND TRICKS

=head2 Common mistake 1

Writing

 %(var)

instead of

 %(var)s

=head2 Common mistake 2 (a bit more newbish)

Writing

 sprintf $format, %hash, ...;

instead of

 sprintf $format, \%hash, ...;

=head2 Alternative hashes

You have several hashes (%h1, %h2, %h3) which should be consulted for values.
You can either merge the hash first:

 %h = (%h1, %h2, %h3); # or one of several available module for hash merging
 printfn $format, \%h, ...;

or create a tied hash which can consult hashes for you:

 tie %h, 'Your::Module', \%h1, \%h2, \%h3;
 printfn $format, \%h, ...;

=head1 IMPLEMENTATION NOTES

Currently every format will be converted using a separate sprintf() invocation.
So "<%d> <%(var)s> <%.(var2)f>" will result in three calls.

=head1 SEE ALSO

sprintf() section on L<perlfunc>

L<String::Flogger>

L<String::Formatter>

L<Text::Sprintf::Named>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

