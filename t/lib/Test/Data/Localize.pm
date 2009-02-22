# $Id: /mirror/coderepos/lang/perl/Data-Localize/trunk/t/lib/Test/Data/Localize.pm 101111 2009-02-22T01:12:17.106301Z daisuke  $

package Test::Data::Localize;

BEGIN {
    %ENV = 
        map { ($_ => $ENV{$_}) }
        grep { /^DATA_LOCALIZE/ }
        keys %ENV;
}

1;