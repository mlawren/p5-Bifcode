package Bifcode;
use 5.010;
use strict;
use warnings;
use boolean;
use Carp;
use Exporter::Tidy all => [
    qw( encode_bifcode
      decode_bifcode
      force_bifcode
      diff_bifcode)
];

# ABSTRACT: Serialisation similar to Bencode + undef/UTF8

our $VERSION = '0.001_11';
our ( $DEBUG, $max_depth );

sub _msg { sprintf "@_", pos() || 0 }

my $match = qr/ \G (?|
      (~)
    | (0)
    | (1)
    | (B|U) (?: ( 0 | [1-9] [0-9]* ) : )? 
    | (I) (?: ( 0 | -? [1-9] [0-9]* ) , )?
    | (F) (?: (-)? ( 0 | [1-9] [0-9]* )
        \. ( 0 | [0-9]* [1-9] )
        e (( 0 | -? [1-9] ) [0-9]*) , )?
    | (\[)
    | (\{)
) /x;

sub _decode_bifcode_chunk {
    warn _msg 'decoding at %s' if $DEBUG;

    local $max_depth = $max_depth - 1 if defined $max_depth;

    if ( !m/$match/gc ) {
        croak _msg m/ \G \z /xgc
          ? 'unexpected end of data at %s'
          : 'garbage at %s';
    }

    if ( $1 eq '~' ) {
        return undef;
    }
    elsif ( $1 eq '0' ) {
        return boolean::false;
    }
    elsif ( $1 eq '1' ) {
        return boolean::true;
    }
    elsif ( $1 eq 'B' ) {
        my $len = $2 // croak _msg 'malformed string length at %s';

        croak _msg 'unexpected end of string data starting at %s'
          if $len > length() - pos();

        my $data = substr $_, pos(), $len;
        pos() = pos() + $len;

        warn _msg BYTES => "(length $len) at %s", if $DEBUG;
        return $data;
    }
    elsif ( $1 eq 'U' ) {
        my $len = $2 // croak _msg 'malformed string length at %s';

        croak _msg 'unexpected end of string data starting at %s'
          if $len > length() - pos();

        utf8::decode( my $str = substr $_, pos(), $len );
        pos() = pos() + $len;

        warn _msg
          UTF8 => "(length $len)",
          $len < 200 ? "[$str]" : (), 'at %s'
          if $DEBUG;

        return $str;
    }
    elsif ( $1 eq 'I' ) {
        if ( defined $2 ) {
            warn _msg INTEGER => $2, 'at %s' if $DEBUG;
            return $2;
        }
        croak _msg 'unexpected end of data at %s' if m/ \G \z /xgc;
        croak _msg 'malformed integer data at %s';
    }
    elsif ( $1 eq 'F' ) {
        croak _msg 'malformed float data at %s'
          if $3 eq '0'
          and $4 eq '0'
          and ( $2 or $5 ne '0' );

        warn _msg
          FLOAT => ( $2 // '' ) . $3 . '.' . $4 . 'e' . $5,
          'at %s'
          if $DEBUG;
        return ( $2 // '' ) . $3 . '.' . $4 . 'e' . $5;
    }
    elsif ( $1 eq '[' ) {
        warn _msg 'LIST at %s' if $DEBUG;

        croak _msg 'nesting depth exceeded at %s'
          if defined $max_depth and $max_depth < 0;

        my @list;
        until (m/ \G \] /xgc) {
            warn _msg 'list not terminated at %s, looking for another element'
              if $DEBUG;
            push @list, _decode_bifcode_chunk();
        }
        return \@list;
    }
    elsif ( $1 eq '{' ) {
        warn _msg 'DICT at %s' if $DEBUG;

        croak _msg 'nesting depth exceeded at %s'
          if defined $max_depth and $max_depth < 0;

        my $last_key;
        my %hash;
        until (m/ \G \} /xgc) {
            warn _msg 'dict not terminated at %s, looking for another pair'
              if $DEBUG;

            croak _msg 'unexpected end of data at %s'
              if m/ \G \z /xgc;

            my $key;
            if (m/ \G (B|U) /xgc) {
                pos() = pos() - 1;
                $key = _decode_bifcode_chunk();
            }
            else {
                croak _msg 'dict key is not a string at %s';
            }

            croak _msg 'duplicate dict key at %s'
              if exists $hash{$key};

            croak _msg 'dict key not in sort order at %s'
              if defined $last_key and $key lt $last_key;

            croak _msg 'dict key is missing value at %s'
              if m/ \G \} /xgc;

            $last_key = $key;
            $hash{$key} = _decode_bifcode_chunk();
        }
        return \%hash;
    }
}

sub decode_bifcode {
    local $_         = shift;
    local $max_depth = shift;
    croak 'decode_bifcode: too many arguments: ' . "@_" if @_;
    croak 'decode_bifcode: only accepts bytes' if utf8::is_utf8($_);

    my $deserialised_data = _decode_bifcode_chunk();
    croak _msg 'trailing garbage at %s' if $_ !~ m/ \G \z /xgc;
    return $deserialised_data;
}

my $number_qr = qr/\A ( 0 | -? [1-9] [0-9]* )
                    ( \. ( [0-9]+? ) 0* )?
                    ( e ( -? [0-9]+ ) )? \z/xi;

sub _encode_bifcode {
    map {
        if ( !defined $_ ) {
            '~';
        }
        elsif ( ( my $type = ref $_ ) eq '' ) {
            if ( $_ =~ $number_qr ) {
                if ( defined $3 or defined $5 ) {

                    # normalize to BIFCODE_FLOAT standards
                    my $x = 'F' . ( 0 + $1 )    # remove leading zeros
                      . '.' . ( $3 // 0 ) . 'e' . ( 0 + ( $5 // 0 ) ) . ',';
                    $x =~ s/ ([1-9]) (0+ e)/.${1}e/x;    # remove trailing zeros
                    $x;
                }
                else {
                    'I' . $_ . ',';
                }
            }
            else {
                utf8::encode( my $str = $_ );
                'U' . length($str) . ':' . $str;
            }
        }
        elsif ( $type eq 'SCALAR' or $type eq 'Bifcode::BYTES' ) {
            croak 'Bifcode::BYTES must be defined' unless defined $$_;
            'B' . length($$_) . ':' . $$_;
        }
        elsif ( $type eq 'Bifcode::UTF8' ) {
            my $str = $$_ // croak 'Bifcode::UTF8 must be defined';
            utf8::encode($str);    #, sub { croak 'invalid Bifcode::UTF8' } );
            'U' . length($str) . ':' . $str;
        }
        elsif ( $type eq 'ARRAY' ) {
            '[' . join( '', map _encode_bifcode($_), @$_ ) . ']';
        }
        elsif ( $type eq 'HASH' ) {
            '{' . join(
                '',
                do {
                    my @k = sort keys %$_;
                    map {
                        my $k = shift @k;

                        # if ( is valid utf8($k) ) {
                        utf8::encode($k);
                        ( 'U' . length($k) . ':' . $k, $_ );

                        # }
                        # else {
                        #     ('B' . length($k) . ':' . $k, $_);
                        # }
                    } _encode_bifcode( @$_{@k} );
                  }
            ) . '}';
        }
        elsif ( $type eq 'boolean' ) {
            $$_ ? '1' : '0';
        }
        elsif ( $type eq 'Bifcode::INTEGER' ) {
            croak 'Bifcode::INTEGER must be defined' unless defined $$_;
            if ( $$_ =~ m/\A (?: 0 | -? [1-9] [0-9]* ) \z/x ) {
                sprintf 'I%s,', $$_;
            }
            else {
                croak 'invalid integer: ' . $$_;
            }
        }
        elsif ( $type eq 'Bifcode::FLOAT' ) {
            croak 'Bifcode::FLOAT must be defined' unless defined $$_;
            if ( $$_ =~ $number_qr ) {
                my $x = 'F' . ( 0 + $1 )    # remove leading zeros
                  . '.' . ( $3 // 0 ) . 'e' . ( 0 + ( $5 // 0 ) ) . ',';
                $x =~ s/ ([1-9]) (0+ e)/.${1}e/x;    # remove trailing zeros
                $x;
            }
            else {
                croak 'invalid float: ' . $$_;
            }
        }
        else {
            croak 'unhandled data type: ' . $type;
        }
    } @_;
}

sub encode_bifcode {
    croak 'usage: encode_bifcode($arg)' if @_ != 1;
    goto &_encode_bifcode;
}

sub force_bifcode {
    my $ref  = shift;
    my $type = shift;

    croak 'ref and type must be defined' unless defined $ref and defined $type;
    bless \$ref, 'Bifcode::' . uc($type);
}

sub _expand_bifcode {
    my $bifcode = shift;
    $bifcode =~ s/ (
            [~\[\]\{\}]
            | (U|B) [0-9]+ :  
            | F -? [0-9]+ \. [0-9]+ e -? [0-9]+ ,  
            | I [0-9]+ ,  
        ) /\n$1/gmx;
    $bifcode =~ s/ \A \n //mx;
    $bifcode . "\n";
}

sub diff_bifcode {
    croak 'usage: diff_bifcode($b1, $b2, [$diff_args])'
      unless @_ >= 2 and @_ <= 3;
    my $b1        = shift;
    my $b2        = shift;
    my $diff_args = shift || { STYLE => 'Unified' };

    require Text::Diff;

    $b1 = _expand_bifcode($b1);
    $b2 = _expand_bifcode($b2);
    return Text::Diff::diff( \$b1, \$b2, $diff_args );
}

decode_bifcode('I1,');

__END__

=pod

=encoding utf8

=head1 NAME

Bifcode - simple serialization format

=head1 VERSION

0.001_11 (yyyy-mm-dd)


=head1 SYNOPSIS

    use boolean;
    use Bifcode qw( encode_bifcode decode_bifcode );
 
    my $bifcode = encode_bifcode {
        bools   => [ boolean::false, boolean::true, ],
        bytes   => \pack( 's<',       255 ),
        integer => 25,
        float   => 1.25e-5,
        undef   => undef,
        utf8    => "\x{df}",
    };

    # 7b 55 35 3a 62 6f 6f 6c 73 5b 30 31    {U5:bools[01
    # 5d 55 35 3a 62 79 74 65 73 42 32 3a    ]U5:bytesB2:
    # ff  0 55 35 3a 66 6c 6f 61 74 46 31    ..U5:floatF1
    # 2e 32 35 65 2d 35 2c 55 37 3a 69 6e    .25e-5,U7:in
    # 74 65 67 65 72 49 32 35 2c 55 35 3a    tegerI25,U5:
    # 75 6e 64 65 66 7e 55 34 3a 75 74 66    undef~U4:utf
    # 38 55 32 3a c3 9f 7d                   8U2:..}

    my $decoded = decode_bifcode $bifcode;

=head1 STATUS

This module and related encoding format are still under development. Do
not use it anywhere near production. Input is welcome.

=head1 DESCRIPTION

Bifcode implements the I<bifcode> serialisation format, a mixed
binary/text encoding with support for the following data types:

=over

=item * Primitive:

=over

=item * Undefined(null)

=item * Booleans(true/false)

=item * Integer numbers

=item * Floating point numbers

=item * UTF8 strings

=item * Binary strings

=back

=item * Structured:

=over

=item * Arrays(lists)

=item * Hashes(dictionaries)

=back

=back

The encoding is simple to construct and relatively easy to parse. There
is no need to escape special characters in strings. It is not
considered human readable, but as it is mostly text it can usually be
visually debugged.

I<Bifcode> can only be constructed canonically; i.e. there is only one
possible encoding per data structure. This property makes it suitable
for comparing structures (using cryptographic hashes) across networks.

In terms of size the encoding is similar to minified JSON. In terms of
speed this module compares well with other pure Perl encoding modules
with the same features.

=head1 MOTIVATION & GOALS

Bifcode was created for a project because none of currently available
serialization formats (Bencode, JSON, MsgPack, Sereal, YAML, etc) met
the requirements of:

=over

=item * Support for undef

=item * Support for UTF8 strings

=item * Support for binary data

=item * Trivial to construct on the fly from within SQLite triggers

=item * Universally-recognized canonical form for hashing

=back

I have no lofty goals or intentions to promote this outside of my
specific case, but would appreciate hearing about other uses.
Constructive discussion is welcome.

=head1 SPECIFICATION

The encoding is defined as follows:

=head2 BIFCODE_UNDEF

A null or undefined value correspond to '~'.

=head2 BIFCODE_TRUE and BIFCODE_FALSE

Boolean values are represented by '1' and '0'.

=head2 BIFCODE_UTF8

A UTF8 string is 'U' followed by the octet length of the encoded string
as a base ten number followed by a colon and the encoded string.  For
example the Perl string "\x{df}" (ß) corresponds to "U2:\x{c3}\x{9f}".

=head2 BIFCODE_BYTES

Opaque data is 'B' followed by the octet length of the data as a base
ten number followed by a colon and then the data itself. For example a
three-byte blob 'xyz' corresponds to 'B3:xyz'.

=head2 BIFCODE_INTEGER

Integers are represented by an 'I' followed by the number in base 10
followed by a ','. For example 'I3,' corresponds to 3 and 'I-3,'
corresponds to -3. Integers have no size limitation. 'I-0,' is invalid.
All encodings with a leading zero, such as 'I03,', are invalid, other
than 'I0,', which of course corresponds to 0.

=head2 BIFCODE_FLOAT

Floats are represented by an 'F' followed by a decimal number in base
10 followed by a 'e' followed by an exponent followed by a ','.  For
example 'F3.0e-1,' corresponds to 0.3 and 'F-0.1e0,' corresponds to
-0.1. Floats have no size limitation.  'F-0.0e0,' is invalid.  All
encodings with an extraneous leading zero, such as 'F03.0e0,', or an
extraneous trailing zero, such as 'F3.10e0,', are invalid.

=head2 BIFCODE_LIST

Lists are encoded as a '[' followed by their elements (also I<bifcode>
encoded) followed by a ']'. For example '[U4:spamU4:eggs]' corresponds
to ['spam', 'eggs'].

=head2 BIFCODE_DICT

Dictionaries are encoded as a '{' followed by a list of alternating
keys and their corresponding values followed by a '}'. For example,
'{U3:cowU3:mooU4:spamU4:eggs}' corresponds to {'cow': 'moo', 'spam':
'eggs'} and '{U4:spam[U1:aU1:b]}' corresponds to {'spam': ['a', 'b']}.
Keys must be BIFCODE_UTF8 or BIFCODE_BYTES and appear in sorted order
(sorted as raw strings, not alphanumerics).

=head1 INTERFACE

=head2 C<encode_bifcode( $datastructure )>

Takes a single argument which may be a scalar, or may be a reference to
either a scalar, an array or a hash. Arrays and hashes may in turn
contain values of these same types. Returns a byte string.

The mapping from Perl to I<bifcode> is as follows:

=over

=item * 'undef' maps directly to BIFCODE_UNDEF.

=item * The C<true> and C<false> functions from the L<boolean>
distribution encode to BIFCODE_TRUE and BIFCODE_FALSE.

=item * Plain scalars are treated as BIFCODE_UTF8 unless:

=over

=item 

They look like canonically represented integers in which case they are
mapped to BIFCODE_INTEGER; or

=item

They look like floats in which case they are mapped to BIFCODE_FLOAT.

=back

=item * SCALAR references become BIFCODE_BYTES.

=item * ARRAY references become BIFCODE_LIST.

=item * HASH references become BIFCODE_DICT.

=back

You can force scalars to be encoded a particular way by passing a
reference to them blessed as Bifcode::BYTES, Bifcode::INTEGER,
Bifcode::FLOAT or Bifcode::UTF8. The C<force_bifcode> function below
can help with creating such references.

This subroutine croaks on unhandled data types.

=head2 C<decode_bifcode( $string [, $max_depth ] )>

Takes a byte string and returns the corresponding deserialised data
structure.

If you pass an integer for the second option, it will croak when
attempting to parse dictionaries nested deeper than this level, to
prevent DoS attacks using maliciously crafted input.

I<bifcode> types are mapped back to Perl in the reverse way to the
C<encode_bifcode> function, with the exception that any scalars which
were "forced" to a particular type (using blessed references) will
decode as unblessed scalars.

Croaks on malformed data.

=head2 C<force_bifcode( $scalar, $type )>

Returns a reference to $scalar blessed as Bifcode::$TYPE. The value of
$type is not checked, but the C<encode_bifcode> function will only
accept the resulting reference where $type is one of 'bytes', 'float',
'integer' or 'utf8'.

=head2 C<diff_bifcode( $bc1, $bc2, [$diff_args] )>

Returns a string representing the difference between two bifcodes. The
inputs do not need to be valid Bifcode; they are only expanded with a
very simple regex before the diff is done. The third argument
(C<$diff_args>) is passed directly to L<Text::Diff>.

Croaks if L<Text::Diff> is not installed.

=head1 DIAGNOSTICS

=over

=item C<trailing garbage at %s>

Your data does not end after the first I<bifcode>-serialised item.

You may also get this error if a malformed item follows.

=item C<garbage at %s>

Your data is malformed.

=item C<unexpected end of data at %s>

Your data is truncated.

=item C<unexpected end of string data starting at %s>

Your data includes a string declared to be longer than the available
data.

=item C<malformed string length at %s>

Your data contained a string with negative length or a length with
leading zeroes.

=item C<malformed integer data at %s>

Your data contained something that was supposed to be an integer but
didn't make sense.

=item C<dict key not in sort order at %s>

Your data violates the I<bifcode> format constaint that dict keys must
appear in lexical sort order.

=item C<duplicate dict key at %s>

Your data violates the I<bifcode> format constaint that all dict keys
must be unique.

=item C<dict key is not a string at %s>

Your data violates the I<bifcode> format constaint that all dict keys
be strings.

=item C<dict key is missing value at %s>

Your data contains a dictionary with an odd number of elements.

=item C<nesting depth exceeded at %s>

Your data contains dicts or lists that are nested deeper than the
$max_depth passed to C<decode_bifcode()>.

=item C<unhandled data type>

You are trying to serialise a data structure that consists of data
types other than

=over

=item *

scalars

=item *

references to arrays

=item *

references to hashes

=item *

references to scalars

=back

The format does not support this.

=back

=head1 BUGS AND LIMITATIONS

Strings and numbers are practically indistinguishable in Perl, so
C<encode_bifcode()> has to resort to a heuristic to decide how to
serialise a scalar. This cannot be fixed.

=head1 SEE ALSO

This distribution includes the L<diff-bifcode> command-line utility for
comparing Bifcodes in files.

=head1 AUTHOR

Mark Lawrence <nomad@null.net>, heavily based on Bencode by Aristotle
Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c):

=over

=item * 2015 by Aristotle Pagaltzis

=item * 2017 by Mark Lawrence.

=back

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

