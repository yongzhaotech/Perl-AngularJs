#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Time;
use Class::Email;
use Class::Utility qw(trim site_encryption unique_id valid_email j_son_js);
use Class::Language;

my $init	= new Class::Initialize();
my @error	= ();
my $reply	= undef;

my $lang = $init->lang();
my $first_name	= trim($init->cgi()->param('first_name'));
my $last_name	= trim($init->cgi()->param('last_name'));
my $middle_name	= trim($init->cgi()->param('middle_name'));
my $password	= $init->cgi()->param('password');
my $email		= lc(trim($init->cgi()->param('email')));

if($first_name eq '') {
	push(@error, LANG_LABELS->{r_first_name}->{$lang});
}
if($last_name eq '') {
	push(@error, LANG_LABELS->{r_last_name}->{$lang});
}
if($email eq '') {
	push(@error, LANG_LABELS->{r_email}->{$lang});
}elsif(!valid_email($email)) {
	push(@error, LANG_LABELS->{w_email}->{$lang});
}
if($password eq '') {
	push(@error, LANG_LABELS->{r_password}->{$lang});
}elsif(!($password =~ /[a-z]+/i && $password =~ /\d+/ && length($password) >= 10 && $password !~ /\s/)) {
	push(@error, LANG_LABELS->{w_password}->{$lang});
}

if(!@error) {
	my @user = $init->sql()->query('select', 'user', { email => $email });
	push(@error, LANG_LABELS->{email_exist}->{$lang}) if(@user);
}
if(!@error) {
	my $time = new Class::Time();
	my $now = $time->call('international');
	my $user = {
		first_name => $first_name,
		middle_name => $middle_name,
		last_name => $last_name,
		email => $email,
		active => 1,# set to 0 when sendmail fully works
		password => site_encryption($email, $password, $init->config('encript')),
		create_time => $now,
		edit_time => $now
	};
	$init->sql()->query('insert', 'user', {}, $user);
	my $id = $init->sql()->key();
	my $verify_str = unique_id();
	my $acc_code = unique_id();
#	$init->sql()->query('update', 'user', { id => $id }, { verify_str => $verify_str, acc_code => $acc_code });
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}else {
		# email user for verification
#			my $body = $init->toolkit('activate_account_email')->string({
#				acc_code => $acc_code,
#				verify_str => $verify_str,
#				first_name => $first_name,
#				now => $now,
#				domain => $init->config('domain')
#			});
#			my $mail = new Class::Email();
#			$mail->type('html');
#			$mail->to($email);
#			$mail->from($init->config('auto_email'));
#			$mail->subject('Great! verify your registration');
#			$mail->body($body);
		#$mail->send();
	}
}

$init->apr()->content_type("application/json");
if(@error) {
	$reply = qq|{"error":|.j_son_js(\@error).qq|}|;
}else {
	$reply = qq|{"message":|.j_son_js([LANG_LABELS->{account_done}->{$lang}]).qq|}|;
}

print $reply;
return Apache2::Const::OK
