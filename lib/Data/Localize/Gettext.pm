# $Id: /mirror/coderepos/lang/perl/Data-Localize/trunk/lib/Data/Localize/Gettext.pm 101683 2009-03-03T15:16:28.102624Z daisuke  $

package Data::Localize::Gettext;
use utf8;
use Encode ();
use Moose;
use MooseX::AttributeHelpers;
use File::Basename ();

with 'Data::Localize::Localizer';

has 'encoding' => (
    is => 'rw',
    isa => 'Str',
    default => 'utf-8',
);

has 'paths' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef[Str]',
    trigger => sub {
        my $self = shift;
        $self->load_from_path($_) for @{$_[0]}
    },
    provides => {
        unshift => 'path_add',
    }
);

after 'path_add' => sub {
    my $self = shift;
    $self->load_from_path($_) for @{ $self->paths };
};

has 'lexicon' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} },
    provides => {
        get => 'lexicon_get',
        set => 'lexicon_set'
    }
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub BUILDARGS {
    my ($class, %args) = @_;

    my $path = delete $args{path};
    if ($path) {
        $args{paths} ||= [];
        push @{$args{paths}}, $path;
    }
    $class->SUPER::BUILDARGS(%args, style => 'gettext');
}

sub register {
    my ($self, $loc) = @_;
    $loc->add_localizer_map('*', $self);

}

sub load_from_path {
    my ($self, $path) = @_;

    return unless $path;

    print STDERR "[Data::Localize::Gettext]: load_from_path - loading from glob($path)\n" if &Data::Localize::DEBUG;

    foreach my $x (glob($path)) {
        $self->load_from_file($x) if -f $x;
    }
}

sub load_from_file {
    my ($self, $file) = @_;

    print STDERR "[Data::Localize::Gettext]: load_from_file - loading from file $file\n" if &Data::Localize::DEBUG;
    my %lexicon;
    open(my $fh, '<', $file) or die "Could not open $file: $!";

    # This stuff here taken out of Locale::Maketext::Lexicon, and
    # modified by daisuke
    my (%var, $key, @comments, @ret, @metadata);
my $UseFuzzy = 0;
my $KeepFuzzy = 0;
my $AllowEmpty = 1;
my @fuzzy;
    my $process    = sub {
        if ( length( $var{msgstr} ) and ( $UseFuzzy or !$var{fuzzy} ) ) {
            $lexicon{ $var{msgid} } = $var{msgstr};
        }
        elsif ($AllowEmpty) {
            $lexicon{ $var{msgid} } = '';
        }
        if ( $var{msgid} eq '' ) {
            push @metadata, $self->parse_metadata( $var{msgstr} );
        }
        else {
            push @comments, $var{msgid}, $var{msgcomment};
        }
        if ( $KeepFuzzy && $var{fuzzy} ) {
            push @fuzzy, $var{msgid}, 1;
        }
        %var = ();
    };

    while (<$fh>) {
        $_ = Encode::decode($self->encoding, $_, Encode::FB_CROAK());
        s/[\015\012]*\z//;                  # fix CRLF issues

        /^(msgid|msgstr) +"(.*)" *$/
            ? do {                          # leading strings
            $var{$1} = $2;
            $key = $1;
            }
            :

            /^"(.*)" *$/
            ? do {                          # continued strings
            $var{$key} .= $1;
            }
            :

            /^# (.*)$/
            ? do {                          # user comments
            $var{msgcomment} .= $1 . "\n";
            }
            :

            /^#, +(.*) *$/
            ? do {                          # control variables
            $var{$_} = 1 for split( /,\s+/, $1 );
            }
            :

            /^ *$/ && %var
            ? do {                          # interpolate string escapes
            $process->($_);
            }
            : ();

    }

    # do not silently skip last entry
    $process->() if keys %var != 0;

    my $lang = File::Basename::basename($file);
    $lang =~ s/\.[mp]o$//;

    print STDERR "[Data::Localize::Gettext]: load_from_file - registering ",
        scalar keys %lexicon, " keys\n" if &Data::Localize::DEBUG;

    # This needs to be merged
    $self->lexicon_merge($lang, \%lexicon);
}

sub lexicon_merge {
    my ($self, $lang, $lexicon) = @_;

    my $old = $self->lexicon_get($lang);
    if ($old) {
        $self->lexicon_set($lang, { %$old, %$lexicon });
    } else {
        $self->lexicon_set($lang, $lexicon);
    }
}

sub parse_metadata {
    my $self = shift;
    return map {
              (/^([^\x00-\x1f\x80-\xff :=]+):\s*(.*)$/)
            ? ( $1 eq 'Content-Type' )
                ? do {
                    my $enc = $2;
                    if ( $enc =~ /\bcharset=\s*([-\w]+)/i ) {
                        $self->encoding($1);
                    }
                    ( "__Content-Type", $enc );
                }
                : ( "__$1", $2 )
            : ();
    } split( /\r*\n+\r*/, $_[0]);
}


1;

__END__

=head1 NAME

Data::Localize::Gettext - Acquire Lexicons From .po Files

=head1 DESCRIPTION

=head1 METHODS

=head2 lexicon_merge

Merges lexicon (may change...)

=head2 load_from_file

Loads lexicons from specified file

=head2 load_from_path

Loads lexicons from specified path. May contain glob()'able expressions.

=head2 register

Registeres this localizer

=head2 parse_metadata

Parse meta data information in .po file

=head1 UTF8 

Currently, strings are assumed to be utf-8,

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

Parts of this code stolen from Locale::Maketext::Lexicon::Gettext.

=head1 COPYRIGHT

=over 4

=item The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=back

=cut