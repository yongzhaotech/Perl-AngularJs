package Class::Session;

use strict;
use warnings;
use Apache::Session::MySQL;

# constructor
# Argument: the first argument is a MYSQL object passed in from the caller, the second is a session id and is optional
# If an existing session id is passed, the session object is returned, if no session id is passed or the passed value is 
# null, a new session object is created and returned to the caller
sub new {
	my ($object, $sql, $session_id) = @_;
	my $class   = ref($object) || $object;
	my $session = { _SQL => $sql, _SESSION => {} };
	eval {
		tie %{$session->{_SESSION}}, "Apache::Session::MySQL", $session_id, {Handle => $sql->handle(), LockHandle => $sql->handle(), TableName => "sessions"};
	};
	return $@ ? undef : bless($session, $class);;
}

sub close { 
	my $self = shift();
	untie (%{$self->{_SESSION}});
	$self->{_SQL}->commit(1);
}

sub delete { 
	my $self = shift();
	tied (%{$self->{_SESSION}})->delete(); 
	$self->close();
}

# check if a session object expires. Arguments: MYSQL object and User object
sub expires {
	my $self = shift;
	my $timeout = 60;
	my @count = $self->{_SQL}->query('select', "SELECT id AS 'expires' FROM sessions WHERE id=? AND update_time < DATE_SUB(now(),INTERVAL $timeout MINUTE) LIMIT 0,1", [$self->{_session_id}]);
	return $count[0]->{expires};
}

# update a session object time value to postpone its timeout
sub update {
	my $self = shift;
	$self->{_SQL}->execute_stmt("UPDATE sessions SET update_time=now() WHERE id=?", [$self->{_SESSION}->{_session_id}]);
	$self->{_SQL}->commit(1);
}

# session id
sub id { 
	my $self = shift();
	return $self->{_SESSION}->{_session_id}; 
}

# getter
# Argument: session element name
# Return value: the value of the passed element
sub get { 
	return undef unless @_ > 1;
	my ($self, $element) = @_;
	return (exists $self->{_SESSION}->{$element}) ? $self->{_SESSION}->{$element} : undef; 
}

# setter
# Argument: a reference to a hash with element name as the hash key and the element value as the hash value
sub set {
	my ($self, $hash_ref) = @_;
	if(defined $hash_ref && ref($hash_ref) =~ /hash/i) {
		foreach(keys %{$hash_ref}) {
			if(!defined $hash_ref->{$_}) {
				delete $self->{_SESSION}->{$_} if(exists($self->{_SESSION}->{$_}));
			}else {
				$self->{_SESSION}->{$_} = $hash_ref->{$_};
			}
		}
		$self->close();
	}
}

sub delete_item {
	my ($self, $element) = @_;
	if(exists $self->{_SESSION}->{$element}) {
		delete $self->{_SESSION}->{$element};
		$self->close();
	}
}

return 1;
