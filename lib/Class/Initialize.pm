package Class::Initialize;

use strict;
use warnings;
use CGI;
use Class::SQL;
use Class::Cookie;
use Class::Session;
use Class::User;
use Class::Advertise;
use Class::Toolkit;
use Class::Content qw (static_content);
use Class::Utility qw (gen_token get_token);
use Class::Language;
$CGI::LIST_CONTEXT_WARN = 0;

# constructor
sub new {
	my $object	= shift();
	my $class	= ref($object) || $object;
		my $self	= {
		_APR			=> Apache2::RequestUtil->request,
		_CGI			=> new CGI(),
		_SQL			=> new Class::SQL(),
		_PAGEURL		=> undef,
		_TEMPLATE		=> undef,
		_SESSION		=> undef,
		_USER			=> undef,
		_ADVERTISE		=> undef,
		_ERROR			=> undef,
		_QUERYSTRING	=> undef,
		_IP				=> undef,
		_LANG			=> 'en',
		_SESSION_ACTIVE	=> 0,
		_SUCCESS		=> 1,
		_USER_TEMPLATES	=> {
			admin_advertise		=> 1,
			admin_user			=> 1,
			edit_advertise		=> 1,
			page_permission		=> 1,
			save_category		=> 1,
			save_subcategory	=> 1,
			user_account		=> 1,
			user_advertise		=> 1,
			visitor_hits		=> 1,
			edit_ad				=> 1
		}
	};

	my $c = $self->{_APR}->connection;
	$self->{_IP} = $c->client_ip();	
	my ($path, $page) = ($self->{_APR}->uri() =~ m@^(.*/)([^/]*)$@);
	$page = 'advertise' if($page eq '');
	$self->{_TEMPLATE} = $page;
	$self->{_TEMPLATE} =~ s/\..*//;
	$self->{_PAGE} = $page;
	$self->{_PATH} = $path;

	$self->{_CONFIG} = static_content('site_config');
	my $auth = static_content('site_authenticate');
	$self->{_AUTHENTICATE}->{$page} = $auth->{$page} if(defined $auth && exists($auth->{$page})); 

	$self->{_COOKIE} = new Class::Cookie($self->{_APR});
	$self->{_LANG} = defined $self->{_COOKIE} && defined $self->{_COOKIE}->get("lang") ? $self->{_COOKIE}->get("lang") : $self->{_CGI}->param('site_lang');
	my $session_id = defined $self->{_COOKIE} && defined $self->{_COOKIE}->get("session_id") && $self->{_COOKIE}->get("session_id") ne '' ? $self->{_COOKIE}->get("session_id") : $self->{_CGI}->param('session_id');
	if(defined $session_id && $session_id ne '') {
		$self->{_SESSION} = new Class::Session($self->{_SQL}, $session_id);
		if(defined $self->{_SESSION}) {
			$self->{_USER} = new Class::User($self->{_SQL}, $self->{_SESSION}->get("user_id"));
			if($self->{_SESSION}->expires()) {
				$self->{_SESSION}->delete();
				$self->{_COOKIE}->delete(("session_id"));
			}else {
				$self->{_SESSION}->update();
				$self->{_SESSION_ACTIVE} = 1;
			}	
		}
	}
	
	bless($self, $class);

	$self->querystring($ENV{QUERY_STRING});
	if(exists($self->{_AUTHENTICATE}->{$page})) {
		$self->_check_permission($page);
	}
	
	return $self;
}

sub lang {
	my $self = shift();
	return $self->{_LANG};
}

sub config {
	my ($self, $key) = @_;
	return $self->{_CONFIG}->{$key};
}

sub _check_permission {
	my ($self, $page) = @_;
	if($self->{_SESSION_ACTIVE}) {
		if($self->{_USER}->get('access_level') < $self->{_AUTHENTICATE}->{$page}->{access_level}) {
			$self->{_ERROR} = LANG_LABELS->{no_permission}->{$self->{_LANG}};
		}elsif($self->{_AUTHENTICATE}->{$page}->{check_ad}) {
			$self->{_ADVERTISE} = new Class::Advertise($self->{_SQL}, $self->{_CGI}->param('aid') || $self->{_CGI}->param('advertise_id'));
			if(!defined $self->{_ADVERTISE}) {
				$self->{_ERROR} = LANG_LABELS->{no_such_post}->{$self->{_LANG}};
			}elsif($self->{_ADVERTISE}->get('user_id') ne $self->{_USER}->get('id')) {
				$self->{_ERROR} = LANG_LABELS->{not_your_post}->{$self->{_LANG}};
			}
		}
	}else {
		$self->{_ERROR} = LANG_LABELS->{not_sign_in}->{$self->{_LANG}};
	}
	if(defined $self->{_ERROR}) {
		$self->{_SUCCESS}  = 0;
	}
}

sub user_signed_in {
	my $self = shift();
	return $self->{_SESSION_ACTIVE}; 
}

sub success {
	my $self = shift();
	return $self->{_SUCCESS};
}

sub error {
	my $self = shift();
	return $self->{_ERROR};
}

sub user {
	my $self = shift();
	$self->{_USER} = shift() if(@_);
	return $self->{_USER};
}

sub delete_advertise {
	my $self = shift();
	$self->{_ADVERTISE} = undef;
}

sub advertise {
	my $self = shift();
	$self->{_ADVERTISE} = shift() if(@_);
	return $self->{_ADVERTISE};
}

sub session {
	my $self = shift();
	$self->{_SESSION} = shift() if(@_);
	return $self->{_SESSION};
}

sub cookie {
	my $self = shift();
	return $self->{_COOKIE};
}

sub sql {
	my $self = shift();
	return $self->{_SQL};
}

sub cgi {
	my $self = shift();
	return $self->{_CGI};
}

sub apr {
	my $self = shift();
	return $self->{_APR};
}

sub page {
	my $self = shift();
	return $self->{_PAGE};
}

sub path {
	my $self = shift();
	return $self->{_PATH};
}

sub template {
	my $self = shift();
	$self->{_TEMPLATE} = shift() if(@_);
	return $self->{_TEMPLATE};
}

sub querystring {
	my $self = shift();
	if(@_) {
		my $query_string = shift();
		foreach my $item (split(/\&/, $query_string)) {
			$item =~ m/^(.*)=(.*)$/;
			$self->{_QUERYSTRING}->{$1} = $2;
		}
	}
	return $self->{_QUERYSTRING};
}

sub ip {
	my $self = shift();
	return $self->{_IP};
}

sub toolkit {
	# if an optional template name is passed in, use that template, otherwise use the self template
	my $self = shift();
	return new Class::Toolkit(@_ ? shift() : $self->{_TEMPLATE}, $self);
}

sub is_user_page {
	my $self = shift();
	return exists($self->{_USER_TEMPLATES}->{$self->template()}) ? 1 : 0;
}

sub html {
	my $self = shift();
	$self->{_HTML} = shift() if(@_);
	return $self->{_HTML};
}

sub generate_html {
	my ($self, $aid) = @_;
	return;
	my $toolkit = $self->toolkit($self->config('main_template'));
	$self->querystring("aid=$aid");
	$self->template('ad_detail');
	foreach my $language (qw(en cn)) {
		$self->{gen_html_language} = $language;
		my $token = get_token($self);
		$token->{language} = $language;
		my $output = $toolkit->string($token);
		my $doc = $self->config('doc_root')."/html/$language/".$token->{advertise}->get('html');
		my $disk_doc = $self->config('doc_root')."/html/$language/*-$aid.html";
		`rm -f $disk_doc`;
		$self->html($token->{advertise}->get('html'));
		open(HTML, ">$doc");
		print HTML $output;
		close(HTML);
	}
}

sub token {
	my $self = shift();
	return gen_token($self->{_SQL});
}

1;
