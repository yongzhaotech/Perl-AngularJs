#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Email;
use Class::Utility qw(trim unique_id valid_email j_son_js);
use Class::Language;

my $init	= new Class::Initialize();
my @error	= ();
my $temp	= undef;
my $reply	= undef;
my @user	= ();

my $email	= lc(trim($init->cgi()->param('email')));

if($email eq '') {
	push(@error, LANG_LABELS->{r_email}->{$init->cookie()->get('lang')});
}elsif(!valid_email($email)) {
	push(@error, LANG_LABELS->{w_email}->{$init->cookie()->get('lang')});
}

if(!@error) {
	@user = $init->sql()->query('select', 'user', { email => $email });
	push(@error, LANG_LABELS->{email_not_found}->{$init->cookie()->get('lang')}) if(!@user);
}
if(!@error) {
	my $id = $user[0]->{id};
	my $pwd_str = unique_id();
	my $acc_code = unique_id();
	$init->sql()->query('update', 'user', { id => $id }, { acc_code => $acc_code.$pwd_str });
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}else {
		my $body = {
			plain => $init->toolkit('reset_password_email_plain')->string({
				crlf => "\n",
				acc_code => $acc_code.$pwd_str,
				first_name => $user[0]->{first_name},
				domain => $init->config('domain')
			}),
			html => $init->toolkit('reset_password_email_'.$init->cookie()->get('lang'))->string({
				acc_code => $acc_code.$pwd_str,
				first_name => $user[0]->{first_name},
				domain => $init->config('domain')
			})
		};
		my $mail = new Class::Email();
		$mail->to($email);
		$mail->from($init->config('info_email'));
		$mail->subject(LANG_LABELS->{set_pwd_sub}->{$init->cookie()->get('lang')});
		$mail->body($body);
		$mail->send();
	}
}

$init->apr()->content_type("application/json");
if(@error) {
	$reply = qq|{"error":|.j_son_js(\@error).qq|}|;
}else {
	$temp = $init->toolkit('ng_success');
	$reply = "parent.window.clear_box()";
	$reply = qq|{"message":|.j_son_js([LANG_LABELS->{reset_link_sent}->{$init->cookie()->get('lang')}]).qq|}|;
}

print $reply;
return Apache2::Const::OK
