package Class::Cookie;

use strict;
use warnings;

# constructor
# Arguement: Apache2::RequestUtil->request
sub new {
	my ($object, $r) = @_;
	my $class  = ref($object) || $object;
	my $self   = { _req => $r, cookie => {}, path => "/ads/", expires => "Saturday, 01-JAN-00 00:00:00 GMT" };
	my $cookie = $r->headers_in()->{'Set-Cookie'};
	if($cookie) {
        foreach (split(m/; */o, $cookie)) {
            my ($name, $value) = m/(.*)=(.*)/o;
			$self->{cookie}->{$name} = $value;
        }
	}
	if(!defined $self->{cookie}->{lang} || $self->{cookie}->{lang} !~ /^(:?cn|en)$/) {
		$self->{cookie}->{lang} = 'en';
		$r->err_headers_out->add('Set-Cookie' => "lang=en; path=$self->{path}");
	}
	return bless($self, $class);
}

# setter
# Argument: a reference to a hash with the cookie name as the hash key and the cookie value as the hash value
# Return: a reference to an array of cookie
sub set {
	return undef unless @_ > 1;
	my ($self, $hash_ref) = @_;
	foreach(keys %{$hash_ref}) {
		$self->{cookie}->{$_} = $hash_ref->{$_};
		my $cookie = "$_=$hash_ref->{$_}; path=$self->{path}";
#		$cookie .= "; httponly" unless $_ eq 'lang';
		$self->{_req}->err_headers_out->add('Set-Cookie' => $cookie);
	}
}

# getter
# Argument: cookie name
# return: cookie value
sub get { 
	return undef unless @_ > 1;
	my ($self, $name) = @_;
	return exists($self->{cookie}->{$name}) ? $self->{cookie}->{$name} : undef; 
}

# return an array of cookie names
sub names { 
	my $self = shift();
	return keys %{$self->{cookie}}; 
}

# Argument: an array of cookie names, optional, if no argument is passed, all the cookies are deleted
# return: a reference to an array of cookie
sub delete {
	my $self = shift();
	foreach(@_ ? @_ : $self->names()) {
		my $cookie = "$_=; ";
		$cookie .= "path=$self->{path}; " if($self->{path});
		$cookie .= "expires=$self->{expires}";
		$self->{_req}->err_headers_out->add('Set-Cookie' => $cookie);
	}
}

return 1;
