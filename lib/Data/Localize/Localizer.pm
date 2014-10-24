
package Data::Localize::Localizer;
use utf8;
use Any::Moose '::Role';
use Any::Moose '::Util::TypeConstraints';
use Carp ();

requires 'register', 'get_lexicon';

has 'style' => (
    is => 'ro',
    isa => enum([qw(gettext maketext)]),
    default => 'maketext',
);

no Any::Moose '::Role';
no Any::Moose '::Util::TypeConstraints';

sub localize_for {
    my ($self, %args) = @_;
    my ($lang, $id, $args) = @args{ qw(lang id args) };

    my $value = $self->get_lexicon($lang, $id) or return ();
    if (Data::Localize::DEBUG()) {
        print STDERR "[Data::Localize::Localizer]: localize_for - $id -> ",
            defined($value) ? $value : '(null)', "\n";
    }
    return $self->format_string($value, @$args) if $value;
    return ();
}

sub format_string {
    my ($self, $value, @args) = @_;

    my $style = $self->style;
    if ($style eq 'gettext') {
        $value =~ s/%(\d+)/ defined $args[$1 - 1] ? $args[$1 - 1] : '' /ge;
    } elsif ($style eq 'maketext') {
        $value =~ s|\[([^\]]+)\]|
            my @vars = split(/,/, $1);
            my $method;
            if ($vars[0] !~ /^_(-?\d+)$/) {
                $method = shift @vars;
            }


            ($method) ?
                $self->$method( map { (/^_(-?\d+)$/) ? $args[$1 - 1] : $_; } @args ) :
                @args[ map { (/^_(-?\d+)$/ ? $1 : $_) - 1 } @vars ];
        |gex;
    } else {
        Carp::confess("Unknown style: $style");
    }
    return $value;
}

1;

__END__

=head1 NAME

Data::Localize::Localizer - Localizer Role

=head1 SYNOPSIS

    package MyLocalizer;
    use Moose;

    with 'Data::Localize::Localizer';

    no Moose;

=head1 METHODS

=head2 localize_for

=head2 format_string

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

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