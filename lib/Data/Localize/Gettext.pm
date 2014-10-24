
package Data::Localize::Gettext;
use utf8;
use Any::Moose;
use Carp ();
use Data::Localize::Gettext::Parser;
use File::Temp ();
use Data::Localize::Util qw(_alias_and_deprecate);
use Data::Localize::Storage::Hash;

extends 'Data::Localize::Localizer';
with 'Data::Localize::Trait::WithStorage';

has encoding => (
    is => 'ro',
    isa => 'Str',
    default => 'utf-8',
);

has paths => (
    is => 'ro',
    isa => 'ArrayRef',
    trigger => sub {
        my $self = shift;
        $self->load_from_path($_) for @{$_[0]};
    },
);

has use_fuzzy => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has allow_empty => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has _parser => (
    is => 'ro',
    isa => 'Data::Localize::Gettext::Parser',
    lazy_build => 1,
);

override register => sub {
    my ($self, $loc) = @_;
    super();
    $loc->add_localizer_map('*', $self);
};

no Any::Moose;

sub _build__parser {
    my $self = shift;
    return Data::Localize::Gettext::Parser->new(
        use_fuzzy  => $self->use_fuzzy(),
        keep_empty => $self->allow_empty(),
        encoding   => $self->encoding(),
    );
}

sub BUILDARGS {
    my ($class, %args) = @_;

    my $path = delete $args{path};
    if ($path) {
        $args{paths} ||= [];
        push @{$args{paths}}, $path;
    }
    $class->SUPER::BUILDARGS(%args);
}

sub _build_formatter {
    Any::Moose::load_class( 'Data::Localize::Format::Gettext' );
    return Data::Localize::Format::Gettext->new();
}

sub add_path {
    my $self = shift;
    push @{$self->paths}, @_;
    $self->load_from_path($_) for @_;
}

sub get_lexicon_map {
    my ($self, $key) = @_;
    return $self->lexicon_map->{ $key };
}

sub set_lexicon_map {
    my ($self, $key, $value) = @_;
    return $self->lexicon_map->{ $key } = $value;
}

sub load_from_path {
    my ($self, $path) = @_;

    return unless $path;

    if (Data::Localize::DEBUG()) {
        print STDERR "[Data::Localize::Gettext]: load_from_path - loading from glob($path)\n" 
    }

    foreach my $x (glob($path)) {
        $self->load_from_file($x) if -f $x;
    }
}

sub load_from_file {
    my ($self, $file) = @_;

    if (Data::Localize::DEBUG()) {
        print STDERR "[Data::Localize::Gettext]: load_from_file - loading from file $file\n"
    }

    my $lexicon = $self->_parser->parse_file($file);

    my $lang = File::Basename::basename($file);
    $lang =~ s/\.[mp]o$//;

    if (Data::Localize::DEBUG()) {
        print STDERR "[Data::Localize::Gettext]: load_from_file - registering ",
            scalar keys %{$lexicon}, " keys\n"
    }

    # This needs to be merged
    $self->merge_lexicon($lang, $lexicon);
}

_alias_and_deprecate path_add => 'add_path';

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Localize::Gettext - Acquire Lexicons From .po Files

=head1 DESCRIPTION

=head1 METHODS

=head2 format_string($value, @args)

Formats the string

=head2 add_path($path, ...)

Adds a new path where .po files may be searched for.

=head2 get_lexicon($lang, $id)

Gets the specified lexicon

=head2 set_lexicon($lang, $id, $value)

Sets the specified lexicon

=head2 merge_lexicon

Merges lexicon (may change...)

=head2 get_lexicon_map($lang)

Get the lexicon map for language $lang

=head2 set_lexicon_map($lang, \%lexicons)

Set the lexicon map for language $lang

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
