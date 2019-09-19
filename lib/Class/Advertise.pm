package Class::Advertise;

use strict;
use warnings;
use Class::BaseObject;
our @ISA = qw(BaseObject);

sub new {
	my ($object, $sql, $id) = @_;
	my $class	= ref($object) || $object;
	my @data	= $sql->query('select', 'advertise', { id => $id });
	return undef unless(@data);
	my $self	= $class->SUPER::new($sql, 'advertise', 'id');
	my $data	= shift(@data);
	foreach(keys %{$data}) {
		$self->{$_} = $data->{$_};
		$self->{_COLUMNS}->{$_} = 1;
	}
	my @picts = ();
	my $main_pict = undef;
	foreach($sql->query('select', "select * from picture where advertise_id=? order by edit_time desc", [$id])) {
		push(@picts, $_);
		$main_pict = $_ if($_->{is_main});
	}
	$self->{main_picture} = defined($main_pict) ? $main_pict : $picts[0];
	$self->{main_picture} ||= { id => 0 };
	$self->{pictures} = [@picts];
	return bless($self, $class);
}

return 1;
