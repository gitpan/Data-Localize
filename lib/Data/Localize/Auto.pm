# $Id: /mirror/coderepos/lang/perl/Data-Localize/trunk/lib/Data/Localize/Auto.pm 100692 2009-02-15T05:17:58.132409Z daisuke  $

package Data::Localize::Auto;
use Moose;

with 'Data::Localize::Localizer';

__PACKAGE__->meta->make_immutable;

no Moose;

sub register {}

sub localize_for {
    my ($self, %args) = @_;
    my ($id, $args) = @args{ qw(id args) };

    my $value = $id;
    if (&Data::Localize::DEBUG) {
        print STDERR "[Data::Localize::Auto]: localize_for - $id -> ",
            defined($value) ? $value : '(null)', "\n";
    }
    return $self->format_string($value, @$args) if $value;
    return ();
}

1;

=head1 NAME

Data::Localize::Auto - Fallback Localizer

=head1 SYNOPSIS

    # Internal use only

=head1 METHODS

=head2 register

Does nothing

=head2 localize_for

Uses the string ID as the localization source

=cut
