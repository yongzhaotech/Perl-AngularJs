#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Utility qw(create_ad_detail_data j_son_js);
use Class::Language;

my $init		= new Class::Initialize();
my $page_data	= {};
my $reply		= undef;
my $result		= 0;
create_ad_detail_data($init, $page_data, \$result);
if($result) {
	$reply = $page_data->{angular_ad};
}else {
	$reply = qq|{"error":|.j_son_js([LANG_LABELS->{no_sch_result}->{$init->lang()}]).qq|}|;
}
$init->apr()->content_type("application/json");
print $reply;
return Apache2::Const::OK
