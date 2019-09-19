#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Email;
use Class::Utility qw(trim is_nothing valid_email gen_token valid_token is_nothing html_paragraph j_son_js j_son);
use Class::Language;

my $init	= new Class::Initialize();
my $action	= trim($init->cgi()->param('action')) || trim($init->cgi()->param('f_action'));
my @error	= ();
my $reply	= undef;

if($action eq 'contact_us') {
	my $email	= lc(trim($init->cgi()->param('email')));
	my $message	= trim($init->cgi()->param('message')); 
	my $subject = trim($init->cgi()->param('subject'));
	my $token	= trim($init->cgi()->param('token'));
	if(valid_token($init->sql(), $token)) {
		if($email eq '') {
			push(@error, LANG_LABELS->{r_email}->{$init->cookie()->get('lang')});
		}elsif(!valid_email($email)) {
			push(@error, LANG_LABELS->{w_email}->{$init->cookie()->get('lang')});
		}
		if($subject eq '') {
			push(@error, LANG_LABELS->{r_subject}->{$init->cookie()->get('lang')});
		}
		if(is_nothing($message)) {
			push(@error, LANG_LABELS->{r_message}->{$init->cookie()->get('lang')});
		}
		if(!@error) {
			my $mail = new Class::Email();
			$mail->from($init->config('info_email'));
			$mail->reply_to($email);
			$mail->subject($subject);
			$mail->to($init->config('admin_email'));
			$mail->body({plain => $message, html => $message});
			$mail->send();
			$reply = $init->toolkit('ng_success')->string({ execute_js_functions => "parent.window.clear_box()", server_response => j_son_js([LANG_LABELS->{contact_sent}->{$init->cookie()->get('lang')}]) });
			$init->sql()->execute_stmt("delete from server_token where token=?", [$token]);
			$init->sql()->commit();
		}
	}
	$init->apr()->content_type("text/html");
}elsif($action eq 'ask_poster') {
	my $id		= trim($init->cgi()->param('advertise_id'));
	my $email	= lc(trim($init->cgi()->param('email')));
	my $message	= trim($init->cgi()->param('message')); 
	my $token	= trim($init->cgi()->param('token'));
	if(valid_token($init->sql(), $token)) {
		if($email eq '') {
			push(@error, LANG_LABELS->{r_email}->{$init->cookie()->get('lang')});
		}elsif(!valid_email($email)) {
			push(@error, LANG_LABELS->{w_email}->{$init->cookie()->get('lang')});
		}
		if(is_nothing($message)) {
			push(@error, LANG_LABELS->{r_message}->{$init->cookie()->get('lang')});
		}
		if(@error) {
			$reply = $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
		}else {
			my $lang = $init->cookie()->get('lang');
			my $ad = ($init->sql()->query('select', 'advertise', { id => $id }, ['html','currency','name','user_id','price','contact_method','contact_email','create_time','now() as today']))[0];
			if(defined $ad) {
				$ad->{create_time} =~ s/ .*//;
				my $user = ($init->sql()->query('select', 'user', { id => $ad->{user_id} }, ['first_name','last_name','email']))[0];
				my $title = $ad->{contact_method} =~ /\bemail\b/ ? LANG_LABELS->{buddy}->{$lang} : ($lang eq 'en' ? "$user->{first_name} $user->{last_name}" : "$user->{last_name} $user->{first_name}");
				my $rcpt = $ad->{contact_method} =~ /\bemail\b/ ? $ad->{contact_email} : $user->{email};
				my $body = {
					plain => $init->toolkit("ask_poster_plain_$lang")->string({
						crlf => "\n",
						title => $title,
						email => $email,
						name => $ad->{name},
						time => $ad->{create_time},
						price => LANG_LABELS->{'currency_'.$ad->{currency}}->{$lang}.$ad->{price},
						message => $message,
						domain => $init->config('domain'),
						today => $ad->{today}
					}),
					html => $init->toolkit("ask_poster_html_$lang")->string({
						title => $title,
						email => $email,
						web_root => $init->config('web_root'),
						id => $id,
						name => $ad->{name},
						time => $ad->{create_time},
						price => LANG_LABELS->{'currency_'.$ad->{currency}}->{$lang}.$ad->{price},
						message => html_paragraph($message),
						domain => $init->config('domain'),
						today => $ad->{today}
					})
				};
				my $mail = new Class::Email();
				$mail->reply_to($email);
				$mail->to($rcpt);
				$mail->from($init->config('info_email'));
				$mail->subject($ad->{name});
				$mail->body($body);
				$mail->send();
				$reply = $init->toolkit('ng_success')->string({ execute_js_functions => "parent.window.clear_box()", server_response => j_son_js([LANG_LABELS->{msg_sent_to_seller}->{$lang}]) });
				$init->sql()->execute_stmt("delete from server_token where token=?", [$token]);
				$init->sql()->commit();
			}else {
				$reply = $init->toolkit('ng_errors')->string({ server_response => j_son_js([LANG_LABELS->{no_ad_found}->{$lang}]) });
			}
		}
	}
	$init->apr()->content_type("text/html");
}elsif($action eq 'email_ad_friend') {
	my $sender = lc(trim($init->cgi()->param('email')));
	my $friend = lc(trim($init->cgi()->param('friend_email')));
	my $aid = trim($init->cgi()->param('aid'));
	my $token = trim($init->cgi()->param('token'));
	if(valid_token($init->sql(), $token)) {
		my $ad = undef;
		if($sender eq '') {
			push(@error, LANG_LABELS->{r_email}->{$init->cookie()->get('lang')});
		}elsif(!valid_email($sender)) {
			push(@error, LANG_LABELS->{w_email}->{$init->cookie()->get('lang')});
		}
		if($friend eq '') {
			push(@error, LANG_LABELS->{r_friend_email}->{$init->cookie()->get('lang')});
		}elsif(!valid_email($friend)) {
			push(@error, LANG_LABELS->{w_friend_email}->{$init->cookie()->get('lang')});
		}
		if($aid eq '') {
			push(@error, LANG_LABELS->{info_missing}->{$init->cookie()->get('lang')});
		}
		if(!@error) {
			my @ad = $init->sql()->query('select', 'advertise', { id => $aid }, ['html','currency','name','price','create_time','now() as today']);
			if(@ad) {
				$ad = $ad[0];
			}else {
				push(@error, LANG_LABELS->{no_ad_found}->{$init->cookie()->get('lang')});
			}
		}
		if(!@error) {
			$ad->{create_time} =~ s/ .*//;
			my $body = {
				plain => $init->toolkit('email_to_friend_plain_'.$init->cookie()->get('lang'))->string({
					crlf => "\n",
					sender => $sender,
					name => $ad->{name},
					time => $ad->{create_time},
					price => LANG_LABELS->{'currency_'.$ad->{currency}}->{$init->cookie()->get('lang')}.$ad->{price},
					domain => $init->config('domain'),
					today => $ad->{today}
				}),
				html => $init->toolkit('email_to_friend_html_'.$init->cookie()->get('lang'))->string({
					sender => $sender,
					web_root => $init->config('web_root'),
					id => $aid,
					name => $ad->{name},
					time => $ad->{create_time},
					price => LANG_LABELS->{'currency_'.$ad->{currency}}->{$init->cookie()->get('lang')}.$ad->{price},
					domain => $init->config('domain'),
					today => $ad->{today}
				})
			};
			my $mail = new Class::Email();
			$mail->reply_to($sender);
			$mail->from($init->config('info_email'));
			$mail->subject(LANG_LABELS->{friend_share_sub}->{$init->cookie()->get('lang')});
			$mail->to($friend);
			$mail->body($body);
			$mail->send();
			$reply = $init->toolkit('ng_success')->string({ execute_js_functions => "parent.window.clear_box()", server_response => j_son_js([LANG_LABELS->{link_sent}->{$init->cookie()->get('lang')}." $friend"]) });
			$init->sql()->execute_stmt("delete from server_token where token=?", [$token]);
			$init->sql()->commit();
		}
	}
	$init->apr()->content_type("text/html");
}elsif($action eq 'retrieve_visitor_post') {
	my $email_phone = lc(trim($init->cgi()->param('email_phone')));
	my $post_id = trim($init->cgi()->param('post_id'));
	my @ads = $init->sql()->query('select', 'select id, user_id from advertise where post_id=? and (contact_phone=? or contact_email=?)', [$post_id, $email_phone, $email_phone]);
	if(!@ads) {
		push(@error, LANG_LABELS->{no_retrieve_result}->{$init->cookie()->get('lang')});
	}else {
		my ($id, $uid) = ($ads[0]->{id}, $ads[0]->{user_id});	
		require Class::Session;
		my $session = undef;
		if(defined $init->cookie()->get('v_session_id')) {
			$session = new Class::Session($init->sql(), $init->cookie()->get('v_session_id'));
			if(defined $session) {
				if($session->expires()) {
					$session->delete();
					$init->cookie()->delete(("v_session_id"));
					$session = undef;
				}else {
					$session->update();
				}
			}
		}
		if(!defined $session) {
			$session = new Class::Session($init->sql());
			$session->update();
			$init->cookie()->set({v_session_id=>$session->id()});
		}
		$session->set({v_ad_id=>$id, v_user_id=>$uid, v_post_id=>$post_id});
		# create a temporay session and add the ad id into the session
		$reply = $init->toolkit('load_page')->string({ page => "visitor_ad" });
	}
	$init->apr()->content_type("text/html");
}elsif($action eq 'admin_visitor_hits_list') {
    if(!$init->user_signed_in() || $init->user()->get('access_level') < 2) {
        $init->apr()->content_type("text/plain");
        push(@error, LANG_LABELS->{no_permission}->{$init->cookie()->get('lang')});
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
}elsif($action eq 'gen_token') {
	$init->apr()->content_type("application/json");
	$reply = j_son({token=>gen_token($init->sql())});
}elsif($action eq 'see_hit') {
	$init->apr()->content_type("application/json");
	my $page = '';
	my $id = $init->cgi()->param('id');
	if($id) {
		$page = ($init->sql()->query('select', 'advertise', {id=>$id}, ['name']))[0]->{name};
	}else {
		my @arr = split(/\//, $init->cgi()->param('uri'));
		$page = $arr[-1];
	}
	$init->sql()->execute_stmt('update advertise set viewed=viewed+1 where id=?', [$init->cgi()->param('id')]);
	$init->sql()->execute_stmt(qq|insert into visitor_hits (ip,create_time,uri) VALUES (?,now(),?)|,[$init->ip(), $page]);
	$init->sql()->commit();
	$reply = j_son({ok=>'done!'});
}

if(@error) {
	$reply = $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
}
print $reply;
return Apache2::Const::OK
