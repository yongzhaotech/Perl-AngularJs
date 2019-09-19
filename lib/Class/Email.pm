package Class::Email;

use strict;
use warnings;
use MIME::Base64;
use Class::Utility qw(unique_id);

sub new {
	my $object	= shift();
	my $class	= ref($object) || $object;
	my $self	= {
		_MAIL => @_ ? shift : {}
	};
	$self->{_BOUNDARY}	= unique_id();
	$self->{_TIME}		= localtime();
	return bless($self, $class);
}

sub subject {
	my $self = shift;
	$self->{_MAIL}->{subject} = @_ ? shift : 'No Subject';
	$self->{_MAIL}->{subject} = "=?UTF-8?B?"._trim_header(encode_base64($self->{_MAIL}->{subject}))."?=";
}

sub from {
	my $self = shift;
	my $from = @_ ? shift : undef;
	$self->{_MAIL}->{from} = $from if defined $from;
}

sub reply_to {
	my $self		= shift;
	my $reply_to	= @_ ? shift : undef;
	$self->{_MAIL}->{reply_to} = $reply_to if defined $reply_to;
}

sub to {
	my $self	= shift;
	my $to		= @_ ? shift : undef;
	if(defined $to) {
		$self->{_MAIL}->{to} = $self->{_MAIL}->{to} ? "$self->{_MAIL}->{to},$to" : $to;
	}
}

sub cc {
	my $self	= shift;
	my $cc		= @_ ? shift : undef;
	if(defined $cc) {
		$self->{_MAIL}->{cc} = $self->{_MAIL}->{cc} ? "$self->{_MAIL}->{cc},$cc" : $cc;
	}
}

sub body {
	my $self = shift;
	my $body = @_ ? shift : undef;
	$self->{_MAIL}->{body} = $body if defined $body;
	$self->{_MAIL}->{body}->{plain} = encode_base64($self->{_MAIL}->{body}->{plain}) if($self->{_MAIL}->{body}->{plain});
	$self->{_MAIL}->{body}->{html} = encode_base64($self->{_MAIL}->{body}->{html}) if($self->{_MAIL}->{body}->{html});
}

sub signature {
	my $self = shift;
	use Mail::DKIM::Signer;
	my $dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha256",
		Method => "relaxed/relaxed",
		Domain => "esaleshome.com",
		Selector => "laoye1",
		KeyFile => "/home/laoye/sites/keys/dk.key",
	);
	eval {
		$dkim->PRINT("Date: $self->{_TIME}\015\012");
		$dkim->PRINT("Subject: $self->{_MAIL}->{subject}\015\012");
		$dkim->PRINT("From: $self->{_MAIL}->{from}\015\012");
		$dkim->PRINT("To: $self->{_MAIL}->{to}\015\012");
		$dkim->PRINT("Reply-To: $self->{_MAIL}->{reply_to}\015\012") if($self->{_MAIL}->{reply_to});
		$dkim->PRINT("Cc: $self->{_MAIL}->{cc}\015\012") if($self->{_MAIL}->{cc});
		$dkim->PRINT(qq|MIME-Version: 1.0\015\012|);
		$dkim->PRINT(qq|Content-Type: multipart/alternative; boundary="_----------=_$self->{_BOUNDARY}"\015\012|);
		$dkim->PRINT(qq|\015\012|);
		$dkim->PRINT(qq|--_----------=_$self->{_BOUNDARY}\015\012|);
		$dkim->PRINT(qq|Content-Type: text/plain; charset="UTF-8"\015\012|);
		$dkim->PRINT(qq|Content-Transfer-Encoding: base64\015\012|);
		$self->{_MAIL}->{body}->{plain} =~ s/[\r\n]/\015\012/g;
		$dkim->PRINT("\015\012".$self->{_MAIL}->{body}->{plain}."\015\012");
		$dkim->PRINT(qq|--_----------=_$self->{_BOUNDARY}\015\012|);
		$dkim->PRINT(qq|Content-Type: text/html; charset="UTF-8"\015\012|);
		$dkim->PRINT(qq|Content-Transfer-Encoding: base64\015\012|);
		$self->{_MAIL}->{body}->{html} =~ s/[\r\n]/\015\012/g;
		$dkim->PRINT("\015\012".$self->{_MAIL}->{body}->{html}."\015\012");
		$dkim->PRINT(qq|--_----------=_$self->{_BOUNDARY}--\015\012|);
		$dkim->PRINT(qq|\015\012|);
		$dkim->CLOSE();
	};
	return $dkim->signature->as_string;
}

sub send {
	my $self = shift;
	$self->{_MAIL}->{subject} = "No subject" unless($self->{_MAIL}->{subject});
	my $msg = $self->signature();
	$msg .= qq|\015\012|;
	$msg .= qq|Date: $self->{_TIME}\015\012|;
	$msg .= qq|Subject: $self->{_MAIL}->{subject}\015\012|;
	$msg .= qq|From: $self->{_MAIL}->{from}\015\012|;
	$msg .= qq|To: $self->{_MAIL}->{to}\015\012|;
	$msg .= qq|Reply-To: $self->{_MAIL}->{reply_to}\015\012| if($self->{_MAIL}->{reply_to});
	$msg .= qq|Cc: $self->{_MAIL}->{cc}\015\012| if($self->{_MAIL}->{cc});
	$msg .= qq|MIME-Version: 1.0\015\012|;
	$msg .= qq|Content-Type: multipart/alternative; boundary="_----------=_$self->{_BOUNDARY}"\015\012|;
	$msg .= qq|\015\012|;
	$msg .= qq|--_----------=_$self->{_BOUNDARY}\015\012|;
	$msg .= qq|Content-Type: text/plain; charset="UTF-8"\015\012|;
	$msg .= qq|Content-Transfer-Encoding: base64\015\012|;
	$msg .= qq|\015\012|;
	$msg .= $self->{_MAIL}->{body}->{plain};
	$msg .= qq|\015\012|;
	$msg .= qq|--_----------=_$self->{_BOUNDARY}\015\012|;
	$msg .= qq|Content-Type: text/html; charset="UTF-8"\015\012|;
	$msg .= qq|Content-Transfer-Encoding: base64\015\012|;
	$msg .= qq|\015\012|;
	$msg .= $self->{_MAIL}->{body}->{html};
	$msg .= qq|\015\012|;
	$msg .= qq|--_----------=_$self->{_BOUNDARY}--\015\012|;
	$msg .= qq|\015\012|;
	open (MAIL,"| /usr/lib/sendmail -oem -t -f laoye") || die "can't open /usr/lib/sendmail - $!";
	print MAIL $msg;# GO!
	close MAIL;
	$self->{_MAIL} = {};# free for next 
}

sub _trim_header {
    my $str = shift;
    $str =~ s/[\r\n]//g;
    return $str;
}

1;
