#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Time;
use Class::Utility qw(trim site_encryption valid_email j_son_js j_son);
use Class::Language;

my $init	= new Class::Initialize();
my @error	= ();

my $email		= lc(trim($init->cgi()->param('email')));
my $password	= $init->cgi()->param('password');
my $user		= undef;
my $lang = $init->lang();

$init->apr()->content_type("application/json");

if($email eq '') {
	push(@error, LANG_LABELS->{r_email}->{$lang});
}elsif(!valid_email($email)) {
	push(@error, LANG_LABELS->{w_email}->{$lang});
}else {
	$user = ($init->sql()->query('select', 'user', { email => $email }))[0];
	if(!defined $user) {
		push(@error, LANG_LABELS->{email_not_found}->{$lang});
	}else {
		if(!$user->{active}) {
			push(@error, "This account has not been activated yet, have you ever checked your email for the account activation?");
		}elsif($user->{locked}) {
			push(@error, "This account has been locked for security concern, have you ever checked your email to have the account unlocked?");
		}	
	}
}

if(!@error) {
	if($password eq '') {
		push(@error, LANG_LABELS->{r_password}->{$lang});
	}else {
		if($user->{password} ne site_encryption($email, $password, $init->config('encript'))) {
			push(@error, LANG_LABELS->{wrong_password}->{$lang});
		}
	}
}

if(@error) {
	print qq|{"error":|.j_son_js(\@error).qq|}|;
}else {
	use Class::User;
	use Class::Session;
	my $time = new Class::Time();
	my $now = $time->call('international');
	my $cookie = $init->cookie();	
	my $user_o = new Class::User($init->sql(), $user->{id});
	my $session = new Class::Session($init->sql());
	$session->update($init->sql());
	$user_o->set({session_id=>$session->id(),signin_count=>($user_o->get('signin_count') + 1),last_sign_in=>($user_o->get('last_sign_in') ? $user_o->get('last_sign_in').','.$now : $now)});
	$cookie->set({session_id=>$session->id()});
	$init->session($session);
	$init->user($user_o);
	$session->set({user_id=>$user->{id}});
	$init->sql()->commit();
	print qq|{"user":|.j_son({email=>$user_o->get('email'),first_name=>$user_o->get('first_name'),last_name=>$user_o->get('last_name'),access_level=>$user_o->get('access_level')}).qq|}|; 
}
return Apache2::Const::OK
