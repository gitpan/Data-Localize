# $Id: /mirror/coderepos/lang/perl/Data-Localize/trunk/lib/Data/Localize/Localizer.pm 100692 2009-02-15T05:17:58.132409Z daisuke  $

package Data::Localize::Localizer;
use utf8;
use Moose::Role;
use Moose::Util::TypeConstraints;

requires 'register';

has 'style' => (
    is => 'rw',
    isa => enum([qw(gettext maketext)]),
    default => 'maketext',
);

no Moose::Role;
no Moose::Util::TypeConstraints;

sub localize_for {
    my ($self, %args) = @_;
    my ($lang, $id, $args) = @args{ qw(lang id args) };

    my $lexicon = $self->lexicon_get($lang) or return ();
    my $value = $lexicon->{ $id };
    if (&Data::Localize::DEBUG) {
        print STDERR "[Data::Localize::Localizer]: localize_for - $id -> ",
            defined($value) ? $value : '(null)', "\n";
    }
    return $self->format_string($value, @$args) if $value;
    return ();
}

sub format_string {
    my ($self, $value, @args) = @_;

    my $style = $self->style;
print STDERR "$self -> localizing '$value' with (@args), style is $style\n" if Data::Localize::DEBUG();
    if ($style eq 'gettext') {
        $value =~ s/%(\d+)/ $args[$1 - 1] || '' /ge;
    } elsif ($style eq 'maketext') {
        $value =~ s/\[_(\d+)\]/$args[$1 - 1] || ''/ge;
    } else {
        confess "Unknown style: $style";
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


=cut