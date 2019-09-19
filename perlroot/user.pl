#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Language;
use Class::Session;
use Class::Utility qw(j_son create_edit_ad_data);

my $init	= new Class::Initialize();

my $action	= $init->cgi()->param('action');
my $lang = $init->lang();
$init->apr()->content_type("application/json");

my $response = j_son({error=>LANG_LABELS->{sign_outed}->{$lang}});
my $session = $init->session();

if(defined $session) {
	my $user_id = $session->get('user_id');
	if($action eq 'fetch_user_profile') {
		if(defined $user_id) {
			$response = j_son({user=>($init->sql()->query('select', 'user', { id => $user_id }, ['email','access_level','first_name','last_name']))[0]});
		}
	}elsif($action eq 'fetch_user_ads') {
		if(defined $user_id) {
			my @ads = ();
			my $sth = $init->sql()->handle()->prepare("select id,name,viewed,description,is_free,price from advertise where user_id=? and active=1 order by create_time desc");
			$sth->execute(($user_id));
			while(my $ad = $sth->fetchrow_hashref()) {
				$ad->{description} =~ s/[\n]/<br>/g;
				push(@ads, $ad);
			}
			$sth->finish();
			$response = j_son({ads=>\@ads});
		}	
	}elsif($action eq 'fetch_user_ad') {
		if(defined $user_id) {
			my $page_data = {user_id=>$user_id, advertise_id=>$init->cgi()->param('advertise_id')};
			create_edit_ad_data($init, $page_data);
			if($page_data->{angular_ad}) {
				$response = qq|{"angular_ad":|.$page_data->{angular_ad}.qq|}|;
			}else {
				$response = j_son({error=>'Error'});
			}
		}
	}elsif($action eq 'sign_out') {
		if(defined $session) {
			$session->delete();
			$init->cookie()->delete('session_id');
			$response = j_son({ok=>1});
		}else {
			$response = j_son({error=>LANG_LABELS->{sign_outed}->{$lang}});
		}
	}
}

print $response;
return Apache2::Const::OK
