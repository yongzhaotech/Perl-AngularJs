#! /usr/bin/perl
use strict;
use warnings;
use Class::Utility qw(trim j_son_js);
use Class::Initialize;
use Class::Language;

my $init = new Class::Initialize();
$init->apr()->content_type("application/json");

if(!$init->success()) {
	print qq|{"error":|.j_son_js([$init->error()]).qq|}|;
	return Apache2::Const::OK
}

my $id = $init->cgi()->param('aid');
my @images = ();
my @error	= ();

my @user_ad = $init->sql()->query('select', 'advertise', { id => $id });
if(@user_ad) {
	if($user_ad[0]->{user_id} eq $init->user()->get('id')) {
		@images = $init->sql()->query('select', 'picture', { advertise_id => $id });
		$init->sql()->query('delete', 'advertise', { id => $id });
		$init->sql()->query('delete', 'picture', { advertise_id => $id });
	}else {
		push(@error, LANG_LABELS->{not_your_post}->{$init->cookie()->get('lang')});
	}
}else {
	push(@error, LANG_LABELS->{no_such_post}->{$init->cookie()->get('lang')});
}

$init->sql()->commit();
if($init->sql()->error()) {
	push(@error, $init->sql()->error_string());
}
	
if(@error) {
	print qq|{"error":|.j_son_js(\@error).qq|}|;
}else {
	foreach(@images) {
		my $small = $init->config('small_image').'/'.$_->{id}.'.jpg';
		my $big = $init->config('big_image').'/'.$_->{id}.'.jpg';
		my $large = $init->config('large_image').'/'.$_->{id}.'.jpg';
		`rm $small`;
		`rm $big`;
		`rm $large`;
	}
	print qq|{"ok":{}}|;
}
return Apache2::Const::OK
