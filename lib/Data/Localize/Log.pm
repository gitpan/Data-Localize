package Data::Localize::Log;
use strict;
use base qw(Exporter);
use Log::Minimal;
our @EXPORT = @Log::Minimal::EXPORT;

$Log::Minimal::ENV_DEBUG = 'DATA_LOCALIZE_DEBUG';
$Log::Minimal::PRINT = sub {
    printf STDERR "%5s [%s] %s\n",
        $$,
        $_[1],
        $_[2],
};

1;
