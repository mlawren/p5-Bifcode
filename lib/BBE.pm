package BBE;
use 5.008001;
use strict;
use warnings;
use Carp;
use Exporter::Tidy all => [qw( encode_bbe decode_bbe bless_bbe )];
use Unicode::UTF8 qw/decode_utf8 encode_utf8/;

# ABSTRACT: Serialisation similar to Bencode + undef/UTF8

our $VERSION = '0.001';
our ( $DEBUG, $max_depth );
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

            return $data;
        }

        my $str = decode_utf8( substr $_, pos(), $len );
        pos() = pos() + $len;

        warn _msg
          STRING => "(length $len)",
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
    elsif (m/ \G l /xgc) {
        warn _msg 'LIST' if $DEBUG;

        croak _msg 'nesting depth exceeded at %s'
          if defined $max_depth and $max_depth < 0;

        my @list;
        until (m/ \G $EOC /xgc) {
            warn _msg 'list not terminated at %s, looking for another element'
              if $DEBUG;
            push @list, _decode_bbe_chunk();
        }
        return \@list;
    }
    elsif (m/ \G d /xgc) {
        warn _msg 'DICT' if $DEBUG;

        croak _msg 'nesting depth exceeded at %s'
          if defined $max_depth and $max_depth < 0;

        my $last_key;
        my %hash;
        until (m/ \G $EOC /xgc) {
            warn _msg 'dict not terminated at %s, looking for another pair'
              if $DEBUG;

            croak _msg 'unexpected end of data at %s'
              if m/ \G \z /xgc;

            my $key = _decode_bbe_string();
            defined $key or croak _msg 'dict key is not a string at %s';

            croak _msg 'duplicate dict key at %s'
              if exists $hash{$key};

            croak _msg 'dict key not in sort order at %s'
              if defined $last_key and $key lt $last_key;

            croak _msg 'dict key is missing value at %s'
              if m/ \G $EOC /xgc;

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
    my $ref_data = ref $data;

    return '~' unless defined $data;

    if ( not ref $data ) {
        return sprintf 'i%s' . $EOC, $data
          if $data =~ m/\A (?: 0 | -? [1-9] \d* ) \z/x;

        my $str = encode_utf8($data);
        return length($str) . ':' . $str;
    }
    elsif ( $ref_data eq 'BBE::INTEGER' ) {
        croak 'BBE::INTEGER must be defined' unless defined $$data;
        return sprintf 'i%s' . $EOC, $$data
          if $$data =~ m/\A (?: 0 | -? [1-9] \d* ) \z/x;
        croak 'invalid integer: ' . $$data;
    }
    elsif ( $ref_data eq 'SCALAR' or $ref_data eq 'BBE::STRING' ) {
        croak 'BBE::STRING must be defined' unless defined $$data;

        # escape hatch -- use this to avoid num/str heuristics
        my $str = encode_utf8($$data);
        return length($str) . ':' . $str;
    }
    elsif ( $ref_data eq 'ARRAY' ) {
        return 'l' . join( '', map _encode_bbe($_), @$data ) . $EOC;
    }
    elsif ( $ref_data eq 'HASH' ) {
        return 'd'
          . join( '',
            map { _encode_bbe( \$_ ), _encode_bbe( $data->{$_} ) }
            sort keys %$data )
          . $EOC;
    }
    elsif ( $ref_data eq 'BBE::BYTES' ) {
        croak 'BBE::BYTES must be defined' unless defined $$data;
        return 'b' . length($$data) . ':' . $$data;
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

    use BBE qw( encode_bbe decode_bbe );
 
    my $bbe = encode_bbe { 'age' => 25, 'eyes' => 'blue' };
    print $bbe, "\n"; # d3:agei25,4:eyes4:blue,
 
    my $decoded = decode_bbe $bbe;

=head1 DESCRIPTION

This module implements the I<bbe> serialisation format. It takes most
of its inspiration and code from the L<Bencode> module. If you do not
have a specific requirement for I<bencode> then I<bbe> has the
following advantages (in this humble author's opinion):

=over

=item * Support for undefined values

=item * Support for UTF8-encoded strings

=item * Improved readability

=back

The encoding is defined as follows:

=over

=item * Undefined values correspond to '~'.

=item * UTF8 strings are length-prefixed with a base ten number
followed by a colon and the octet version of the string.  For example
'ß' corresponds to '2:ß'.

=item * Byte strings start with 'b' then the length as a base
ten number followed by a colon and then the byte version of the string.
For example 'xyz' corresponds to 'b3:xyz'.

=item * Integers are represented by an 'i' followed by the number in
base 10 followed by a ','. For example 'i3,' corresponds to 3 and
'i-3,' corresponds to -3. Integers have no size limitation. 'i-0,' is
invalid. All encodings with a leading zero, such as 'i03,', are
invalid, other than 'i0,', which of course corresponds to 0.

=item * Lists are encoded as an 'l' followed by their elements (also
encode_bbe'd) followed by a ','. For example 'l4:spam4:eggs,' corresponds
to ['spam', 'eggs'].

=item * Dictionaries are encoded as a 'd' followed by a list of
alternating keys and their corresponding values followed by a ','. For
example, 'd3:cow3:moo4:spam4:eggs,' corresponds to {'cow': 'moo',
'spam': 'eggs'} and 'd4:spaml1:a1:b,, corresponds to {'spam': ['a',
'b']}. Keys must be strings and appear in sorted order (sorted as raw
strings, not alphanumerics).

=back

=head1 INTERFACE

=head2 C<encode_bbe( $datastructure )>

Takes a single argument which may be a scalar, or may be a reference to
either a scalar, an array or a hash. Arrays and hashes may in turn
contain values of these same types. Returns a byte string.

Plain scalars that look like canonically represented integers will be
serialised as such. To bypass the heuristic and force serialisation as
a string, use a reference to a scalar.

Strings are assumed to be UTF8-encoded. To encode as bytes pass a
reference to the data blessed as BBE::BYTES.  Likewise BBE::INTEGER and
BBE::STRING can be used to force detection of those types as well. See
the C<bless_bbe> helper function below.

Croaks on unhandled data types.

=head2 C<decode_bbe( $string [, $max_depth ] )>

Takes a byte string and returns the corresponding deserialised data
structure.

If you pass an integer for the second option, it will croak when
attempting to parse dictionaries nested deeper than this level, to
prevent DoS attacks using maliciously crafted input.

Croaks on malformed data.

=head2 C<bless_bbe( $scalar, $type )>

Returns a reference to $scalar blessed as BBE::$TYPE. The value of
$type is not checked, but the C<encode_bbe> function will only accept
the resulting reference where $type is one of 'bytes', 'integer' or
'string'.

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

