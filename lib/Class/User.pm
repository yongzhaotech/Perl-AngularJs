package Class::User;

use strict;
use warnings;
use Class::BaseObject;
our @ISA = qw(BaseObject);

sub new {
	my ($object, $sql, $id) = @_;
	my $class	= ref($object) || $object;
	my @data	= $sql->query('select', 'user', { id => $id });
	return undef unless(@data);
	my $self	= $class->SUPER::new($sql, 'user', 'id');
	my $data	= shift(@data);
	foreach(keys %{$data}) {
		$self->{$_} = $data->{$_};
		$self->{_COLUMNS}->{$_} = 1;
	}
	return bless($self, $class);
}

return 1;

