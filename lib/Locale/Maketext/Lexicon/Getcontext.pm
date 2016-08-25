package Locale::Maketext::Lexicon::Getcontext;

use strict;

use Locale::Maketext::Lexicon::Gettext;

our $VERSION = "0.01";
our ( $InputEncoding, $OutputEncoding, $DoEncoding );

# vars
*InputEncoding  = \$Locale::Maketext::Lexicon::Gettext::InputEncoding;
*OutputEncoding = \$Locale::Maketext::Lexicon::Gettext::OutputEncoding;
*DoEncoding     = \$Locale::Maketext::Lexicon::Gettext::DoEncoding;

# functions
*input_encoding     = \&Locale::Maketext::Lexicon::Gettext::input_encoding;
*output_encoding    = \&Locale::Maketext::Lexicon::Gettext::output_encoding;
*parse_metadata     = \&Locale::Maketext::Lexicon::Gettext::parse_metadata;
*parse_mo           = \&Locale::Maketext::Lexicon::Gettext::parse_mo;
*transform          = \&Locale::Maketext::Lexicon::Gettext::transform;
*_unescape          = \&Locale::Maketext::Lexicon::Gettext::_unescape;
*_gettext_to_maketext
    = \&Locale::Maketext::Lexicon::Gettext::_gettext_to_maketext;


#
# parse()
# -----
# copy-pasted from Locale::Maketext::Lexicon::Gettext, with s/msgid/msgctxt/g
#
sub parse {
    my $self = shift;
    my ( %var, $key, @ret );
    my @metadata;
    my @comments;
    my @fuzzy;

    $InputEncoding = $OutputEncoding = $DoEncoding = undef;

    use Carp;
    Carp::cluck "Undefined source called\n" unless defined $_[0];

    # Check for magic string of MO files
    return parse_mo( join( '', @_ ) )
        if ( $_[0] =~ /^\x95\x04\x12\xde/ or $_[0] =~ /^\xde\x12\x04\x95/ );

    local $^W;    # no 'uninitialized' warnings, please.

    require Locale::Maketext::Lexicon;
    my $KeepFuzzy = Locale::Maketext::Lexicon::option('keep_fuzzy');
    my $UseFuzzy  = $KeepFuzzy
        || Locale::Maketext::Lexicon::option('use_fuzzy');
    my $AllowEmpty = Locale::Maketext::Lexicon::option('allow_empty');
    my $process    = sub {
        if ( length( $var{msgstr} ) and ( $UseFuzzy or !$var{fuzzy} ) ) {
            push @ret, ( map transform($_), @var{ 'msgctxt', 'msgstr' } );
        }
        elsif ($AllowEmpty) {
            push @ret, ( transform( $var{msgctxt} ), '' );
        }
        if ( $var{msgctxt} eq '' ) {
            push @metadata, parse_metadata( $var{msgstr} );
        }
        else {
            push @comments, $var{msgctxt}, $var{msgcomment};
        }
        if ( $KeepFuzzy && $var{fuzzy} ) {
            push @fuzzy, $var{msgctxt}, 1;
        }
        %var = ();
    };

    # Parse PO files
    foreach (@_) {
        s/[\015\012]*\z//;    # fix CRLF issues

        /^(msgctxt|msgstr) +"(.*)" *$/
            ? do {            # leading strings
            $var{$1} = $2;
            $key = $1;
            }
            :

            /^"(.*)" *$/
            ? do {            # continued strings
            $var{$key} .= $1;
            }
            :

            /^# (.*)$/
            ? do {            # user comments
            $var{msgcomment} .= $1 . "\n";
            }
            :

            /^#, +(.*) *$/
            ? do {            # control variables
            $var{$_} = 1 for split( /,\s+/, $1 );
            }
            :

            /^ *$/ && %var
            ? do {            # interpolate string escapes
            $process->($_);
            }
            : ();

    }

    # do not silently skip last entry
    $process->() if keys %var != 0;

    push @ret, map { transform($_) } @var{ 'msgctxt', 'msgstr' }
        if length $var{msgstr};
    push @metadata, parse_metadata( $var{msgstr} )
        if $var{msgctxt} eq '';

    return wantarray
        ? ( { @metadata, @ret }, {@comments}, {@fuzzy} )
        : ( { @metadata, @ret } );

}


__PACKAGE__

__END__

=encoding UTF-8

=head1 NAME

Locale::Maketext::Lexicon::Getcontext - PO file parser for Maketext

=head1 DESCRIPTION

This module is a very experimental fork/variant of
L<Locale::Maketext::Lexicon::Gettext> where messages are fetched by
their C<msgctxt> instead of their C<msgid>. It is currently mostly
developed to help the I18N of L<OpenFoodFacts|http://openfoodfacts.org/>
and L<OpenBeautyFacts|http://openbeautyfacts.org/>. You probably don't
want to use this, unless you really now what your are doing.

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>,
L<Locale::Maketext::Lexicon::Gettext>

=head1 AUTHORS

=over

=item Sébastien Aperghis-Tramoni <saper@cpan.org>

=item Clinton Gormley <drtech@cpan.org>

=item Audrey Tang <cpan@audreyt.org>

=back

=head1 LICENSE

This program is free software, license under the MIT (X11) license.

