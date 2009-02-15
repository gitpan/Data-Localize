# $Id: /mirror/coderepos/lang/perl/Data-Localize/trunk/lib/Data/Localize/Namespace.pm 100695 2009-02-15T05:40:07.270158Z daisuke  $

package Data::Localize::Namespace;
use Moose;
use MooseX::AttributeHelpers;
use Module::Pluggable::Object;
use Encode ();

with 'Data::Localize::Localizer';

has 'namespaces' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    provides => {
        unshift => 'add_namespaces'
    }
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub register {
    my ($self, $loc) = @_;
    my $finder = Module::Pluggable::Object->new(
        require => 1,
        search_path => [ $self->namespaces ]
    );

    # find the languages that we currently support
    my $re = join('|', $self->namespaces);
    foreach my $plugin ($finder->plugins) {
        $plugin =~ s/^(?:$re):://;
        $plugin =~ s/::/_/g;
        $loc->add_localizer_map($plugin, $self);
    }   
    $loc->add_localizer_map('*', $self);
}

our %LOADED;
sub lexicon_get {
    my ($self, $lang) = @_;

    foreach my $namespace ($self->namespaces) {
        my $klass = "$namespace\::$lang";
        if (&Data::Localize::DEBUG) {
            print STDERR "[Data::Localize::Namespace]: lexicon_get - Trying $klass\n";
        }

        # Catch the very weird case where is_class_loaded() returns true
        # but the class really hasn't been loaded yet.
        no strict 'refs';
        my $first_load = 0;
        if (! $LOADED{$klass}) {
            if (defined %{"$klass\::Lexicon"} && defined %{"$klass\::"}) {
                if (&Data::Localize::DEBUG) {
                    print STDERR "[Data::Localize::Namespace]: lexicon_get - class already loaded\n";
                }
            } else {
                if (&Data::Localize::DEBUG) {
                    print STDERR "[Data::Localize::Namespace]: lexicon_get - loading $klass\n";
                }
                eval "require $klass";
                if ($@) {
                    if (&Data::Localize::DEBUG) {
                        print STDERR "[Data::Localize::Namespace]: lexicon_get - Failed to load $klass: $@\n";
                    }
                    next;
                }
            }
            if (&Data::Localize::DEBUG) {
                print STDERR "[Data::Localize::Namespace]: lexicon_get - setting $klass to already loaded\n";
            }
            $LOADED{$klass}++;
            $first_load = 1;
        }

        if (&Data::Localize::DEBUG) {
            print STDERR "[Data::Localize::Namespace]: returning lexicon from $klass\n";
            require Data::Dumper;
            print STDERR Data::Dumper::Dumper(\%{"$klass\::Lexicon"});
        }
        my $h = \%{ "$klass\::Lexicon" };
        if ($first_load) {
            my %t;
            while (my($k, $v) = each %$h) {
                if ( ! Encode::is_utf8($k) ) {
                    $k = Encode::decode_utf8($k);
                }
                if ( ! Encode::is_utf8($v) ) {
                    $v = Encode::decode_utf8($v);
                }
                $t{$k} = $v;
            }
            %$h = ();
            %$h = %t;
        }
        return $h;
        
    }
    return ();
}

1;

__END__

=head1 NAME

Data::Localize::Namespace - Acquire Lexicons From Module %Lexicon Hash

=head1 SYNOPSIS

   package MyApp::I18N::ja;
   use strict;
   our %Lexicon = (
      "Hello, %1!" => "%1さん、こんにちは!"
   );

   1;

   use Data::Localize;

   my $loc = Data::Localize::Namespace->new(
      style => "gettext",
      namespace => "MyApp::I18N",
   );
   my $out = $loc->localize_for(
      lang => 'ja',
      id   => 'Hello, %1!',
      args => [ 'John Doe' ]
   );

=head1 METHODS

=head2 register

Registeres this localizer to the Data::Localize object

=head2 lexicon_get 

Looks up lexicon data from given namespaces. Packages must be discoverable
via Module::Pluggable::Object, with a package name like YourNamespace::lang

=cut