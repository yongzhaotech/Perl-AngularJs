#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Utility qw(j_son_js j_son);
use Class::Language;
use Class::Session;

my $init = new Class::Initialize();
my $id = undef;
my $uid = undef;
my $post_id = undef;
my $session = undef;
my @images = ();
my @error = ();
my $lang = $init->lang();
my $v_session_id = defined $init->cookie() && defined $init->cookie()->get("v_session_id") && $init->cookie()->get("v_session_id") ne '' ? $init->cookie()->get("v_session_id") : $init->cgi()->param('v_session_id');
$init->apr()->content_type("application/json");

if(defined $v_session_id) {
	$session = new Class::Session($init->sql(), $init->cookie()->get('v_session_id'));
	if(defined $session) {
		if($session->expires($init->sql())) {
			$session->delete();
			$init->cookie()->delete(('v_session_id'));
		}else {
			$id = $session->get('v_ad_id');
			$uid = $session->get('v_user_id');
			$post_id = $session->get('v_post_id');
		}
	}
	if(!defined $id) {
		print qq|{"error":|.j_son_js([LANG_LABELS->{visitor_in_err}->{$lang}]).qq|}|;
		return Apache2::Const::OK
	}
}
my @user_ad = $init->sql()->query('select', 'advertise', { id => $id, user_id => $uid, post_id => $post_id });
if(@user_ad) {
	@images = $init->sql()->query('select', 'picture', { advertise_id => $id });
	$init->sql()->query('delete', 'advertise', { id => $id });
	$init->sql()->query('delete', 'picture', { advertise_id => $id });
}else {
	push(@error, LANG_LABELS->{no_ad_found}->{$lang});
}

my $doc = $init->config('doc_root')."/html/en/*-$id.html";
`rm -f $doc`;
$doc = $init->config('doc_root')."/html/cn/*-$id.html";
`rm -f $doc`;

$init->sql()->commit(1);
if($init->sql()->error()) {
	push(@error, $init->sql()->error_string());
}
	
if(@error) {
	print qq|{"error":|.j_son_js(\@error).qq|}|;
}else {
	foreach(@images) {
		my $small = $init->config('small_image').'/'.$_->{id}.'.jpg';
		my $big = $init->config('big_image').'/'.$_->{id}.'.jpg';
		`rm $small`;
		`rm $big`;
	}
	$session->delete();
	$init->cookie()->delete(('v_session_id'));
	print j_son({ok=>1});
}
return Apache2::Const::OK
