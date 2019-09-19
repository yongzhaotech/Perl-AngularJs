#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Utility qw(create_search_advertise_data j_son);
use Class::Language;

my $init		= new Class::Initialize();

my $page_data	= {};
my $reply		= undef;
my $result		= 0;
create_search_advertise_data($init, $page_data, \$result);
if($result) {
	$reply = $page_data->{json};
}else {
	$reply = j_son({error=>LANG_LABELS->{no_sch_result}->{$init->cookie()->get('lang')}});		
}
$init->apr()->content_type("application/json");
print $reply;
return Apache2::Const::OK
