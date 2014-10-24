use strict;
use utf8;
use Test::More tests => 15;
use Test::Requires qw(BerkeleyDB YAML::XS);
use t::Data::Localize::Test qw(write_po);

use_ok "Data::Localize";
{
    my $loc = Data::Localize->new(auto => 0, languages => [ 'ja' ]);
    $loc->add_localizer(
        class => 'Gettext',
        path => 't/04_gettext/*.po',
        storage_class => 'BerkeleyDB'
    );
    my $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、こんにちは!', q{translation for "Hello, stranger!" from BerkeleyDB file});

    my $file = write_po( <<'EOM' );
msgid "Hello, stranger!"
msgstr "%1さん、おじゃまんぼう！"
EOM

    $loc->localizers->[0]->add_path($file);
    $out = $loc->localize('Hello, stranger!', '牧大輔');
    is($out, '牧大輔さん、おじゃまんぼう！', q{translation for "Hello, stranger!" from new file after BerkeleyDB});

}

{
    my $loc = Data::Localize->new();
    $loc->add_localizer(
        class => "MultiLevel",
        paths => [ 't/08_multilevel/*.yml' ],
        storage_class => 'BerkeleyDB',
        storage_args => {
            store_as_refs => 1
        }
    );

    {
        $loc->set_languages('en');
        is( $loc->localize( 'hello_world' ), 'Hello, World!', "hello_world (en)" );
        is( $loc->localize( 'greetings.hello', { name => 'John Doe' } ), 'Hello, John Doe', "greetings.hello (en)" );
        is( $loc->localize( 'greetings.morning', { name => 'John Doe' } ), 'Good morning, John Doe', "greetings.morning (en)" );
        is( $loc->localize( 'greetings.afternoon', { name => 'John Doe' } ), 'Good afternoon, John Doe', "greetings.afternoon (en)" );
        is( $loc->localize( 'greetings.evening', { name => 'John Doe' } ), 'Good evening, John Doe', "greetings.evening (en)" );
        is( $loc->localize( 'nonexistent.hello_world' ), 'nonexistent.hello_world' );
    }

    {
        $loc->set_languages('ja', 'en');
        is( $loc->localize( 'hello_world' ), 'こんにちは、世界！', "hello_world (ja)" );
        is( $loc->localize( 'greetings.hello', { name => 'John Doe' } ), 'こんにちは、 John Doe', "greetings.hello (ja)" );
        is( $loc->localize( 'greetings.morning', { name => 'John Doe' } ), 'おはよう、 John Doe', "greetings.morning (ja)" );
        is( $loc->localize( 'greetings.afternoon', { name => 'John Doe' } ), 'こんにちは、 John Doe', "greetings.afternoon (ja)" );
        is( $loc->localize( 'greetings.evening', { name => 'John Doe' } ), 'こんばんは、 John Doe', "greetings.evening (ja)" );
        is( $loc->localize( 'nonexistent.hello_world' ), 'nonexistent.hello_world' );
    }
}