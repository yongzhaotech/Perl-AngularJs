package BaseObject;

use strict;
use warnings;

# object constructor
sub new {
	my ($object, $sql, $table, $key) = @_;
	my $class       = ref($object) || $object;
	my $self		= { 
		_SQL		=> $sql, 
		_TABLE		=> $table,
		_KEY		=> $key,
		_MESSAGE	=> undef 
	};
	return bless($self, $class);
}

# getter
# Argument: element name
# Return value: the value of the passed element
sub get {
	return undef unless @_ > 1;
	my ($self, $element) = @_;
	return (exists $self->{$element}) ? $self->{$element} : undef;
}

sub set {
	my ($self, $hash_ref) = @_;
	my $data = undef;
	if(defined $hash_ref && ref($hash_ref) =~ /hash/i) {
		foreach(keys %{$hash_ref}) {
			if(exists $self->{_COLUMNS}->{$_} && $self->{$_} !~ /^$hash_ref->{$_}$/) {
				$data->{$_} = $hash_ref->{$_};
			}
			$self->{$_} = $hash_ref->{$_};
		}
	}
	# Invoke database call only if a new item or an exiting one with new data is passed
	if(defined $data) {
		$self->{_SQL}->query('update', $self->{_TABLE}, { $self->{_KEY} => $self->{$self->{_KEY}} }, $data);	
	}else {
		$self->{_MESSAGE} = "No data is changed in database";
	}
}

sub delete {
	my $self = shift();
	$self->{_SQL}->query('delete', $self->{_TABLE}, { $self->{_KEY} => $self->{$self->{_KEY}} });
	delete $self->{$_} foreach(keys %{$self});
}

sub message {
	my $self = shift();
	return $self->{_MESSAGE};
}

return 1;
