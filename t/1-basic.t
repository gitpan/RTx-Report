# $File: //member/autrijus/RTx-Report/t/1-basic.t $ $Author: autrijus $
# $Revision: #3 $ $Change: 7987 $ $DateTime: 2003/09/08 18:41:09 $

use Test::More;
use lib qw( /opt/rt3/lib /usr/local/rt3/lib );

unless (eval { require RT::Record; 1 }) {
    plan skip_all => "Can't find RT3 path";
}

plan tests => 1;
use_ok('RTx::Report');

1;
