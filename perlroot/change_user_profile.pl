#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Time;
use Class::Utility qw(trim site_encryption j_son_js);
use Class::Language;

my $init	= new Class::Initialize();
$init->apr()->content_type("text/html");
if(!$init->success()) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js([$init->error()]) });
	return Apache2::Const::OK
}
my @error	= ();
my $temp	= undef;
my $reply	= undef;

my $first_name	= trim($init->cgi()->param('first_name'));
my $last_name	= trim($init->cgi()->param('last_name'));
my $password	= $init->cgi()->param('password');

if($first_name eq '') {
	push(@error, LANG_LABELS->{r_first_name}->{$init->cookie()->get('lang')});
}
if($last_name eq '') {
	push(@error, LANG_LABELS->{r_last_name}->{$init->cookie()->get('lang')});
}
if($password ne '' && !($password =~ /[A-Z]+/ && $password =~ /[a-z]+/ && $password =~ /\d+/ && length($password) >= 10 && $password !~ /\s/)) {
	push(@error, LANG_LABELS->{w_password}->{$init->cookie()->get('lang')});
}

if(!@error) {
	my $time = new Class::Time();
	my $now = $time->call('international');
	my $user = $init->user();
	my $update_data = {
		first_name => $first_name,
		last_name => $last_name,
		edit_time => $now
	};
	if($password ne '') {
		$update_data->{password} = site_encryption($user->get('email'), $password, $init->config('encript'));
	}
	$user->set($update_data);
	$init->sql()->commit();
	push(@error, $init->sql()->error_string()) if($init->sql()->error());
}

$init->apr()->content_type("text/html");
if(@error) {
	$reply = $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
}else {
	$reply = $init->toolkit('ng_success')->string({ server_response => j_son_js([LANG_LABELS->{edit_profile_done}->{$init->cookie()->get('lang')}]) });
}

print $reply;
return Apache2::Const::OK
