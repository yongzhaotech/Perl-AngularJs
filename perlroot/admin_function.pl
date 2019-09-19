#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Utility qw(j_son_js);

my @error = ();
my $reply = '';
my $response = '';
my $execute_js_functions = '';

my $init	= new Class::Initialize();
$init->apr()->content_type("text/html");
if(!$init->success()) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js([$init->error()]) });
	return Apache2::Const::OK
}

my $sql	= $init->sql();

my $action = $init->cgi()->param('admin_action');
if($action eq 'set_permission') {
	my $page = $init->cgi()->param('page');
	my $access_level = $init->cgi()->param('access_level');
	my $check_ad = $init->cgi()->param('check_ad');
	$init->sql()->query('save', 'site_authenticate', { site => 'advertise', page => $page }, { access_level => $access_level, check_ad => $check_ad });
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}else {
		$response = "Permission for '$page' is changed successfully";
	}
}elsif($action =~ /^(de)?activate_ad$/) {
	my $active = $1 eq 'de' ? 0 : 1;
	my $result = $1 eq 'de' ? 'removed from' : 'added to';
	$init->sql()->query('update', 'advertise', { id => $init->cgi()->param('id') }, { active => $active });
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}else {
		$response = "Selected ad is $result the list";
	}
}elsif($action eq 'delete') {
	my $id = $init->cgi()->param('id');
	my @images = $init->sql()->query('select', 'picture', { advertise_id => $id });
	$init->sql()->query('delete', 'advertise', { id => $id });
	$init->sql()->query('delete', 'picture', { advertise_id => $id });
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}else {
		foreach(@images) {
			my $small = $init->config('small_image').'/'.$_->{id}.'.jpg';
			my $big = $init->config('big_image').'/'.$_->{id}.'.jpg';
			my $large = $init->config('large_image').'/'.$_->{id}.'.jpg';
			`rm $small`;
			`rm $big`;
			`rm $large`;
		}
		$response = "Selected ad is removed from the system";
		$execute_js_functions = "parent.window.remove_ad_row('$id')";
	}
	my $doc = $init->config('doc_root')."/html/en/*-$id.html";
	`rm -f $doc`;
	$doc = $init->config('doc_root')."/html/cn/*-$id.html";
	`rm -f $doc`;
}

$init->apr()->content_type("text/html");
if(@error) {
	$reply = $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
}else {
	$reply = $init->toolkit('ng_success')->string({ server_response => j_son_js([$response]), execute_js_functions => $execute_js_functions });
}

print $reply;
return Apache2::Const::OK
