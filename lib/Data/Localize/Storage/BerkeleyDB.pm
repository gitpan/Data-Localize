package Data::Localize::Storage::BerkeleyDB;
use Any::Moose;
use Any::Moose 'Util::TypeConstraints';
use BerkeleyDB;
use Carp ();
use Encode ();
use File::Spec ();
use File::Temp ();

with 'Data::Localize::Storage';

my @bdb_classes = qw( BerkeleyDB::Hash BerkeleyDB::Btree BerkeleyDB::Recno BerkeleyDB::Queue );
class_type($_) for @bdb_classes;

has '_db' => (
    is => 'rw',
    isa => (join '|', @bdb_classes),
    init_arg => 'db',
);

has 'store_as_refs' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

sub is_volatile { 0 }

sub BUILD {
    my ($self, $args) = @_;
    if (! $self->_db) {
        my $class = $args->{bdb_class} || 'Hash';
        if ($class !~ s/^\+//) {
            $class = "BerkeleyDB::$class";
        }
        Any::Moose::load_class($class);

        my $dir = ($args->{dir} ||= File::Temp::tempdir(CLEANUP => 1));
        $args->{bdb_args} ||= {
            -Filename => File::Spec->catfile($dir, $self->lang),
            -Flags    => BerkeleyDB::DB_CREATE(),
        };

        $self->_db( $class->new( $args->{bdb_args} || {} ) ||
            Carp::confess("Failed to create $class: $BerkeleyDB::Error")
        );
    }

    if ( $self->store_as_refs ) {
        require Storable;
    }

    $self;
}

sub get {
    my ($self, $key, $flags) = @_;
    my $value;
    my $rc = $self->_db->db_get($key, $value, $flags || 0);
    if ($rc == 0) {
        if ( $self->store_as_refs ) {
            # Storeable handles utf8 correctly
            my $thawed = Storable::thaw( $value );
            return $thawed->{'__' . __PACKAGE__ . '::key__'}
                if exists $thawed->{'__' . __PACKAGE__ . '::key__'};
            return $thawed;
        }
        else {
            # BerkeleyDB gives us values with the flags off, so put them back on
            return Encode::decode_utf8($value);
        }
    }
    return ();
}

sub set {
    my ($self, $key, $value, $flags) = @_;

    if ( $self->store_as_refs ) {
        unless ( ref $value ) {
            $value = { ('__' . __PACKAGE__ . '::key__') => $value };
        }
        $value = Storable::freeze( $value );
    }

    my $rc = $self->_db->db_put($key, $value, $flags || 0);
    if ($rc != 0) {
        Carp::confess("Failed to set value $key");
    }
}

__PACKAGE__->meta->make_immutable();

no Any::Moose;
no Any::Moose 'Util::TypeConstraints';

1;

__END__

=head1 NAME

Data::Localize::Storage::BerkeleyDB - BerkeleyDB Backend

=head1 SYNOPSIS

    use Data::Localize::Storage::BerkeleyDB;

    Data::Localize::Storage::BerkeleDB->new(
        bdb_class => 'Hash', # default
        bdb_args  => {
            -Filename => ....
            -Flags    => BerkeleyDB::DB_CREATE
        }
    );

=head1 METHODS

=head2 get

=head2 set

=head2 is_volatile

=cut
