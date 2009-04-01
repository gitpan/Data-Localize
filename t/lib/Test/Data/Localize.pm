# $Id: /mirror/coderepos/lang/perl/Data-Localize/trunk/t/lib/Test/Data/Localize.pm 103043 2009-04-01T01:16:45.115159Z daisuke  $

package Test::Data::Localize;

BEGIN {
    %ENV = 
        map { ($_ => $ENV{$_}) }
        grep { /^DATA_LOCALIZE/ || /^ANY_MOOSE/ }
        keys %ENV;
}

1;