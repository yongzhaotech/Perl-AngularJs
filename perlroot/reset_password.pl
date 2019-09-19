#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Utility qw(site_encryption j_son_js);
use Class::Language;

my $init	= new Class::Initialize();
my @error	= ();
my $temp	= undef;
my $reply	= undef;
my @user	= ();

my $lang = $init->lang();
my $password = $init->cgi()->param('new_password');
my $confirm_password = $init->cgi()->param('confirm_new_password');
my $acc_code = $init->cgi()->param('acc_code');

if($password eq '') {
	push(@error, LANG_LABELS->{r_password}->{$lang});
}elsif(!($password =~ /[a-z]+/i && $password =~ /\d+/ && length($password) >= 10 && $password !~ /\s/)) {
	push(@error, LANG_LABELS->{w_password}->{$lang});
}elsif($password ne $confirm_password) {
	push(@error, LANG_LABELS->{w_pwd_no_match}->{$lang});
}

if(!@error) {
	if($acc_code =~ /(:?cn|en)$/) {
		$acc_code =~ s/$1//;
	}
	@user = $init->sql()->query('select', 'user', { acc_code => $acc_code });
	push(@error, LANG_LABELS->{wrong_url_param}->{$lang}) if(!@user);
}
if(!@error) {
	my $id = $user[0]->{id};
	$init->sql()->query('update', 'user', { id => $id }, { acc_code => '', password => site_encryption($user[0]->{email}, $password, $init->config('encript')) });
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}
}

$init->apr()->content_type("text/html");
if(@error) {
	$reply = $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
	print $reply;
}else {
	print $init->toolkit('wait_redirect')->string({ server_response => j_son_js([LANG_LABELS->{pwd_reseted}->{$lang}]), execute_js_functions => "eEngine.model('box').go_to('user_account')" });
}

return Apache2::Const::OK
