#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Language;
use Class::Utility qw(create_admin_user_data create_admin_advertise_data create_page_permission_data create_admin_category create_admin_subcategory create_visitor_hits_data j_son);

my $reply = '';

my $init	= new Class::Initialize();
my $action	= $init->cgi()->param('action');
$init->apr()->content_type("application/json");

if(!$init->success()) {
	print j_son({error=>$init->error()});
	return Apache2::Const::OK
}

if($action eq 'fetch_adm_users') {
	my $page_data = {};
	my $result = 0;
	create_admin_user_data($init, $page_data, \$result);
	if($result) {
		$reply = $page_data->{json};
	}else {
		$reply = j_son({error=>LANG_LABELS->{no_sch_result}->{$init->cookie()->get('lang')}});		
	}
}elsif($action eq 'fetch_adm_ads') {
	my $page_data = {};
	my $result = 0;
	create_admin_advertise_data($init, $page_data, \$result);
	if($result) {
		$reply = $page_data->{json};
	}else {
		$reply = j_son({error=>LANG_LABELS->{no_sch_result}->{$init->cookie()->get('lang')}});		
	}
}elsif($action eq 'fetch_adm_files') {
	my $page_data = {};
	create_page_permission_data($init, $page_data);
	$reply = $page_data->{json};
}elsif($action eq 'fetch_adm_categories') {
	my $page_data = {};
	create_admin_category($init, $page_data);
	$reply = $page_data->{json};
}elsif($action eq 'fetch_adm_subcategories') {
	my $page_data = {};
	create_admin_subcategory($init, $page_data);
	$reply = $page_data->{json};
}elsif($action eq 'fetch_adm_visitor_hits') {
	my $page_data = {};
	create_visitor_hits_data($init, $page_data);
	$reply = $page_data->{json};
}elsif($action eq 'admin_visitor_hits_list') {
    if(!$init->user_signed_in() || $init->user()->get('access_level') < 2) {
        $init->apr()->content_type("text/plain");
        $reply = LANG_LABELS->{no_permission}->{$init->cookie()->get('lang')};
    }else {
        $init->apr()->content_type("application/json");
        my @times = $init->cgi()->param('visitor_date') ?
            $init->sql()->query('select', qq|select substring_index(create_time,' ',-1) as 'create_time',uri from visitor_hits WHERE ip=? and create_time regexp ? ORDER BY create_time DESC|, [$init->cgi()->param('visitor_ip'), $init->cgi()->param('visitor_date')])
            :
            $init->sql()->query('select', qq|select ips.count,ips.ip,substring_index(ips.ip_visit_date,' ',-1) as 'create_time',dayname(substring_index(ips.ip_visit_date,' ',-1)) as 'week_day' from (select count(ip) as 'count',ip,concat(ip,' ',substr(create_time,1,10)) as 'ip_visit_date' from visitor_hits group by ip_visit_date order by ip_visit_date) ips  where ips.ip=? order by create_time desc|, [$init->cgi()->param('visitor_ip')]);
        my $token = {
            lists=>[@times],
            visitor_date=>$init->cgi()->param('visitor_date')
        };
        $reply = j_son({r=>$init->toolkit('visitor_hits_list')->string($token)});
    }
}

print $reply;
return Apache2::Const::OK
