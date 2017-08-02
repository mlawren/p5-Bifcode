package BBE;
use 5.008001;
use strict;
use warnings;
use Carp;
use Exporter::Tidy all => [qw( encode_bbe decode_bbe bless_bbe )];
use Unicode::UTF8 qw/decode_utf8 encode_utf8/;

# ABSTRACT: Serialisation similar to Bencode + undef/UTF8

our $VERSION = '0.001';
our $TRUE    = bless( do { \( my $t = 1 ) }, 'BBE::TRUE' );
our $FALSE   = bless( do { \( my $f = 0 ) }, 'BBE::FALSE' );
our ( $DEBUG, $max_depth, $get_key );
my $EOC = ',';    # End Of Chunk

sub _msg { sprintf "@_", pos() || 0 }

sub _decode_bbe_string {

    if (m/ \G ( b ) ? ( 0 | [1-9] \d* ) : /xgc) {
        my $blob = $1;
        my $len  = $2;

        croak _msg 'unexpected end of string data starting at %s'
          if $len > length() - pos();

        if ($blob) {
            my $data = substr $_, pos(), $len;
            pos() = pos() + $len;

            warn _msg BYTES => "(length $len)", if $DEBUG;

            return $get_key ? $data : \$data;
        }

        my $str = decode_utf8( substr $_, pos(), $len );
        pos() = pos() + $len;

        warn _msg
          UTF8 => "(length $len)",
          $len < 200 ? "[$str]" : ()
          if $DEBUG;

        return $str;
    }

    my $pos = pos();
    if (m/ \G b ? -? 0? \d+ : /xgc) {
        pos() = $pos;
        croak _msg 'malformed string length at %s';
    }
    return;
}

sub _decode_bbe_chunk {
    warn _msg 'decoding at %s' if $DEBUG;

    local $max_depth = $max_depth - 1 if defined $max_depth;

    if ( defined( my $str = _decode_bbe_string() ) ) {
        return $str;
    }
    elsif (m/ \G T /xgc) {
        warn _msg 'TRUE' if $DEBUG;
        return 1;
    }
    elsif (m/ \G F /xgc) {
        warn _msg 'FALSE' if $DEBUG;
        return 0;
    }
    elsif (m/ \G ~ /xgc) {
        warn _msg 'UNDEF' if $DEBUG;
        return undef;
    }
    elsif (m/ \G i /xgc) {
        croak _msg 'unexpected end of data at %s' if m/ \G \z /xgc;

        m/ \G ( 0 | -? [1-9] \d* ) $EOC /xgc
          or croak _msg 'malformed integer data at %s';

        warn _msg INTEGER => $1 if $DEBUG;
        return 0 + $1;
    }
    elsif (m/ \G \[ /xgc) {
        warn _msg 'LIST' if $DEBUG;

        croak _msg 'nesting depth exceeded at %s'
          if defined $max_depth and $max_depth < 0;

        my @list;
        until (m/ \G \] /xgc) {
            warn _msg 'list not terminated at %s, looking for another element'
              if $DEBUG;
            push @list, _decode_bbe_chunk();
        }
        return \@list;
    }
    elsif (m/ \G \{ /xgc) {
        warn _msg 'DICT' if $DEBUG;

        croak _msg 'nesting depth exceeded at %s'
          if defined $max_depth and $max_depth < 0;

        my $last_key;
        my %hash;
        until (m/ \G \} /xgc) {
            warn _msg 'dict not terminated at %s, looking for another pair'
              if $DEBUG;

            croak _msg 'unexpected end of data at %s'
              if m/ \G \z /xgc;

            local $get_key = 1;
            my $key = _decode_bbe_string();
            $get_key = 0;
            defined $key or croak _msg 'dict key is not a string at %s';

            croak _msg 'duplicate dict key at %s'
              if exists $hash{$key};

            croak _msg 'dict key not in sort order at %s'
              if defined $last_key and $key lt $last_key;

            croak _msg 'dict key is missing value at %s'
              if m/ \G \} /xgc;

            $last_key = $key;
            $hash{$key} = _decode_bbe_chunk();
        }
        return \%hash;
    }
    else {
        croak _msg m/ \G \z /xgc
          ? 'unexpected end of data at %s'
          : 'garbage at %s';
    }
}

sub decode_bbe {
    local $_         = shift;
    local $max_depth = shift;
    croak 'decode_bbe: too many arguments: ' . "@_" if @_;
    croak 'decode_bbe: only accepts bytes' if utf8::is_utf8($_);

    my $deserialised_data = _decode_bbe_chunk();
    croak _msg 'trailing garbage at %s' if $_ !~ m/ \G \z /xgc;
    return $deserialised_data;
}

sub _encode_bbe {
    my ($data) = @_;
    return '~' unless defined $data;

    my $ref_data = ref $data;
    if ( $ref_data eq '' ) {
        if ( $data =~ m/\A (?: 0 | -? [1-9] \d* ) \z/x and not $get_key ) {
            $ref_data = 'BBE::INTEGER';
        }
        else {
            $ref_data = 'BBE::STRING';
        }

        my $x = $data;
        $data = \$x;
    }
    elsif ( $ref_data eq 'SCALAR' ) {
        $ref_data = 'BBE::BYTES';
    }

    use bytes;    # for 'sort' and 'length' below

    if ( $ref_data eq 'BBE::TRUE' ) {
        return 'T';
    }
    elsif ( $ref_data eq 'BBE::FALSE' ) {
        return 'F';
    }
    elsif ( $ref_data eq 'BBE::INTEGER' ) {
        croak 'BBE::INTEGER must be defined' unless defined $$data;
        return sprintf 'i%s' . $EOC, $$data
          if $$data =~ m/\A (?: 0 | -? [1-9] \d* ) \z/x;
        croak 'invalid integer: ' . $$data;
    }
    elsif ( $ref_data eq 'BBE::STRING' ) {
        croak 'BBE::STRING must be defined' unless defined $$data;
        my $is_utf8 = 1;
        my $str = encode_utf8( $$data, sub { $is_utf8 = 0 } );
        return length($str) . ':' . $str if $is_utf8;
        return 'b' . length($$data) . ':' . $$data;
    }
    elsif ( $ref_data eq 'BBE::UTF8' ) {
        croak 'BBE::UTF8 must be defined' unless defined $$data;
        my $str = encode_utf8( $$data, sub { croak 'invalid BBE::UTF8' } );
        return length($str) . ':' . $str;
    }
    elsif ( $ref_data eq 'BBE::BYTES' ) {
        croak 'BBE::BYTES must be defined' unless defined $$data;
        return 'b' . length($$data) . ':' . $$data;
    }
    elsif ( $ref_data eq 'ARRAY' ) {
        return '[' . join( '', map _encode_bbe($_), @$data ) . ']';
    }
    elsif ( $ref_data eq 'HASH' ) {
        my $x;
        return '{' . join(
            '',
            map {
                local $get_key = 1;
                $x       = _encode_bbe($_);
                $get_key = 0;
                croak 'BBE::DICT key must be BBE::BYTES or BBE::UTF8'
                  unless $x =~ m/\A [b0-9] /x;
                $x, _encode_bbe( $data->{$_} )
              }
              sort keys %$data
        ) . '}';
    }
    else {
        croak 'unhandled data type: ' . $ref_data;
    }
}

sub encode_bbe {
    croak 'need exactly one argument' if @_ != 1;
    goto &_encode_bbe;
}

sub bless_bbe {
    my $ref  = shift;
    my $type = shift;

    croak 'ref and type must be defined' unless defined $ref and defined $type;
    bless \$ref, 'BBE::' . uc($type);
}

decode_bbe( 'i1' . $EOC );

__END__

=pod

=encoding utf8

=head1 NAME

BBE - simple serialization format

=head1 VERSION

0.001 (yyyy-mm-dd)


=head1 SYNOPSIS

    use BBE qw( encode_bbe decode_bbe bless_bbe );
 
    my $bbe = encode_bbe {
        bytes   => bless_bbe( pack( 's<', 255 ), 'bytes'),
        false   => $BBE::FALSE,
        integer => 25,
        true    => $BBE::TRUE,
        undef   => undef,
        utf8    => 'ß',
    };

    #  '{5:bytesb2:▒5:falseF7:integeri25,4:trueT5:undef~4:utf82:ß}';
 
    my $decoded = decode_bbe $bbe;

    #  {
    #      'true' => 1,
    #      'undef' => undef,
    #      'integer' => 25,
    #      'false' => 0,
    #      'bytes' => \'▒',
    #      'utf8' => "\x{df}"
    #  };

=head1 DESCRIPTION

This module implements the I<bbe> serialisation format. It takes most
of its inspiration and code from the L<Bencode> module. If you do not
have a specific requirement for I<bencode> then I<bbe> has the
following advantages (in this humble author's opinion):

=over

=item * Support for undefined and boolean values

=item * Support for UTF8-encoded strings

=item * Improved readability

=back

The encoding is defined as follows:

=head2 BBE_UNDEF

A null or undefined value correspond to '~'.

=head2 BBE_TRUE and BBE_FALSE

Boolean values are represented by 'T' and 'F'.

=head2 BBE_UTF8

UTF8 strings are the octet length of the decoded string as a base ten
number followed by a colon and the decoded string.  For example "ß"
corresponds to "2:\x{c3}\x{9f}".

=head2 BBE_BYTES

Opaque data starts with a 'b' then the octet length as a base ten
number followed by a colon and then the data itself. For example a
three-byte blob 'xyz' corresponds to 'b3:xyz'.

=head2 BBE_INTEGER

Integers are represented by an 'i' followed by the number in base 10
followed by a ','. For example 'i3,' corresponds to 3 and 'i-3,'
corresponds to -3. Integers have no size limitation. 'i-0,' is invalid.
All encodings with a leading zero, such as 'i03,', are invalid, other
than 'i0,', which of course corresponds to 0.

=head2 BBE_LIST

Lists are encoded as a '[' followed by their elements (also I<bbe>
encoded) followed by a ']'. For example '[4:spam4:eggs]' corresponds to
['spam', 'eggs'].

=head2 BBE_DICT

Dictionaries are encoded as a '{' followed by a list of alternating
keys and their corresponding values followed by a '}'. For example,
'{3:cow3:moo4:spam4:eggs}' corresponds to {'cow': 'moo', 'spam':
'eggs'} and '{4:spam[1:a1:b]} corresponds to {'spam': ['a', 'b']}. Keys
must be BBE_UTF8 or BBE_BYTES and appear in sorted order (sorted as raw
strings, not alphanumerics).

=head1 INTERFACE

=head2 C<encode_bbe( $datastructure )>

Takes a single argument which may be a scalar, or may be a reference to
either a scalar, an array or a hash. Arrays and hashes may in turn
contain values of these same types. Returns a byte string.

Perl data types are automatically mapped to I<bbe> as follows:

=over

=item * Perl's 'undef' maps directly to BBE_UNDEF.

=item * Plain scalars that look like canonically represented integers
will be serialised as BBE_INTEGER. Otherwise they are treated as
BBE_UTF8.

=item * SCALAR references become BBE_BYTES.

=item * ARRAY references become BBE_LIST.

=item * HASH references become BBE_DICT.

=back

You can force scalars to be encoded a particular way by passing a
reference to them blessed as BBE::BYTES, BBE::INTEGER or BBE::UTF8. See
the C<bless_bbe> helper function below for creating those.

The global package variables C<$BBE::TRUE> and C<$BBE::FALSE> are
available for boolean values.

This subroutine croaks on unhandled data types.

=head2 C<decode_bbe( $string [, $max_depth ] )>

Takes a byte string and returns the corresponding deserialised data
structure.

If you pass an integer for the second option, it will croak when
attempting to parse dictionaries nested deeper than this level, to
prevent DoS attacks using maliciously crafted input.

I<bbe> types are mapped to Perl in the reverse way to the C<encode_bbe>
function, with the following additions:

=over

=item * BBE_FALSE maps to 0.

=item * BBE_TRUE maps to 1.

=back

Croaks on malformed data.

=head2 C<bless_bbe( $scalar, $type )>

Returns a reference to $scalar blessed as BBE::$TYPE. The value of
$type is not checked, but the C<encode_bbe> function will only accept
the resulting reference where $type is one of 'bytes', 'false',
'integer', 'true' or 'utf8'.

=head1 DIAGNOSTICS

=over

=item C<trailing garbage at %s>

Your data does not end after the first I<encode_bbe>-serialised item.

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

Your data violates the I<encode_bbe> format constaint that dict keys
must appear in lexical sort order.

=item C<duplicate dict key at %s>

Your data violates the I<encode_bbe> format constaint that all dict
keys must be unique.

=item C<dict key is not a string at %s>

Your data violates the I<encode_bbe> format constaint that all dict
keys be strings.

=item C<dict key is missing value at %s>

Your data contains a dictionary with an odd number of elements.

=item C<nesting depth exceeded at %s>

Your data contains dicts or lists that are nested deeper than the
$max_depth passed to C<decode_bbe()>.

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
C<encode_bbe()> has to resort to a heuristic to decide how to serialise
a scalar. This cannot be fixed.

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

