#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Utility qw(create_advertise_data);

my $init = new Class::Initialize();

my $page_data	= {};
my $start       = $init->cgi()->param('start') || 0;
$init->querystring("start=$start");
create_advertise_data($init, $page_data);
$init->apr()->content_type("application/json");
print qq|{"ads":|.$page_data->{json}.qq|}|;
return Apache2::Const::OK
