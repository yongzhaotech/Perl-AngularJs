package Class::SQL;

use strict;
use warnings;
use DBI; 

# constructor
# if a parameter is passed in, it should be an existing active database handle
sub new {
	my $object		= shift();
	my $class		= ref($object) || $object;
	my $db_config	= { database => "advertise", host => "localhost", port => "3306", user => "aduser", password => "adpassword" };
	my $dbh			= @_ ? shift : DBI->connect("DBI:mysql:database=$db_config->{database};host=$db_config->{host};port=$db_config->{port}", $db_config->{user}, $db_config->{password}, {RaiseError => 1, AutoCommit => 0}) or die($!);
	$dbh->{LongReadLen} = 33554432;#;5242880;
	$dbh->{LongTruncOk} = 0;
	$dbh->do(qq|set names 'utf8'|);
	my $self  = {
		_DB_HANDLE		=> $dbh,
		_INSERT_ID		=> 0,
		_ERROR_STORE	=> [],
	};
	return bless($self, $class);
}

# for update and insert, 'save' command is recommended instead of 'update' and 'insert'
sub query {
	my ($self, $command, $table, $clause, $data) = @_;
	if($command =~ /^select$/i) {
		# type 1 --- query('select', 'coverages', {policy_number=>'8601310',version_number=>'2'}, ['coverage_code','addl_conditions','another_column',...])
		# type 2 --- query('select', 'c.coverage_code,a.effective_date from coverages c,account_inf a where ...', {policy_number=>'8601310',version_number=>'2'})
		return _sql_fetch($self, $table, $clause, $data);
	}elsif($command =~ /^update$/i) {
		return if(!defined $data || ref($data) !~ /^hash$/i || !keys %{$data});
		my @sets = ();
		my @clause = ();
		my @bind = ();
		foreach(sort {$a cmp $b} keys %{$data}) {
			push(@sets, qq|$_=?|);
			push(@bind, $data->{$_});
		}
		foreach(sort {$a cmp $b} keys %{$clause}) {
			push(@clause, qq|$_=?|);
			push(@bind, $clause->{$_});
		}
		my $stmt = qq|update $table set ${\join(",", @sets)} where ${\join(" and ", @clause)}|;
		_sql_execute($self, $stmt, [@bind]);
	}elsif($command =~ /^insert$/i) {
		return if(!defined $data || ref($data) !~ /^hash$/i || !keys %{$data});
		my @place_holder = ();
		my @column = ();
		my @bind = ();
		foreach(sort {$a cmp $b} keys %{$data}) {
			push(@column, $_);
			push(@place_holder, "?");
			push(@bind, $data->{$_});
		}
		my $stmt = qq|insert into $table (${\join(",", @column)}) values (${\join(",", @place_holder)})|;
		_sql_execute($self, $stmt, [@bind]);
	}elsif($command =~ /^delete$/i) {
		my @clause = ();
		my @bind = ();
		foreach(sort {$a cmp $b} keys %{$clause}) {
			push(@clause, qq|$_=?|);
			push(@bind, $clause->{$_});
		}
		my $stmt = @clause ? qq|delete from $table where ${\join(" and ", @clause)}| : qq|delete from $table|;
		_sql_execute($self, $stmt, [@bind]);
	}elsif($command =~ /^delete_2$/i) {
		my @bind = ();
		if(defined $data && ref($data) =~ /^array$/i) {
			# now the $data is clause, an array ref of parameters like ['pol number', 'location id']
			@bind = @{$data};
		}
		my $stmt = qq|delete from $table where $clause|;
		_sql_execute($self, $stmt, [@bind]);
	}elsif($command =~ /^save$/i) {
		return if(!defined $data || ref($data) !~ /^hash$/i || !keys %{$data});
		# recommended for inserting and updating
		my @clause = ();
		my @select_bind = ();
		my $record_exists = 0;
		foreach(sort {$a cmp $b} keys %{$clause}) {
			push(@clause, qq|$_=?|);
			push(@select_bind, $clause->{$_});
		}
		eval {
			my $sth = $self->{_DB_HANDLE}->prepare(qq|select count(*) from $table where ${\join(" and ", @clause)}|);
			$sth->execute(@select_bind);
			($record_exists) = $sth->fetchrow_array();
			$sth->finish();
		};
		if($@) {
			push(@{$self->{_ERROR_STORE}}, $@);
		}
		if($record_exists) {
			my @sets = ();
			my @bind = ();
			foreach(sort {$a cmp $b} keys %{$data}) {
				push(@sets, qq|$_=?|);
				push(@bind, $data->{$_});
			}	
			push(@bind, @select_bind);
			my $stmt = qq|update $table set ${\join(",", @sets)} where ${\join(" and ", @clause)}|;
			_sql_execute($self, $stmt, [@bind]);
		}else {
			my @place_holder = ();
			my @column = ();
			my @bind = ();
			foreach(sort {$a cmp $b} keys %{$clause}) {
				push(@column, $_);
				push(@place_holder, "?");
				push(@bind, $clause->{$_});
			}
			foreach my $col (grep {!exists($clause->{$_})} sort {$a cmp $b} keys %{$data}) {
				push(@column, $col);
				push(@place_holder, "?");
				push(@bind, $data->{$col});
			}
			my $stmt = qq|insert into $table (${\join(",", @column)}) values (${\join(",", @place_holder)})|;
			_sql_execute($self, $stmt, [@bind]);
		}
	}	
}

sub _sql_fetch {
	my ($self, $table, $clause, $columns) = @_;
	$table =~ s/\s+$//;
	$table =~ s/^\s+//;
	my $stmt = "";
	if($table =~ /^[a-z][a-z0-9_]*$/i) { # table name
		$stmt = (defined $columns && ref($columns) =~ /^array$/i) ? "select ${\join(',', @{$columns})} from $table" : "select * from $table";
	}elsif($table =~ /[ ,]/) { # might be join statement
		my $select = $table =~ /^select/i ? "" : "select ";
		$stmt = "$select$table";
	}
	my @clause = ();
	my @bind = ();
	if(ref($clause) =~ /^hash$/i) {
		foreach(sort {$a cmp $b} keys %{$clause}) {
			push(@clause, qq|$_=?|);
			push(@bind, $clause->{$_});
		}
	}
	if(@clause || ($clause && ref($clause) !~ /^hash$/i && ref($clause) !~ /^array$/i)) {
		$stmt = @clause ? qq|$stmt where ${\join(" AND ", @clause)}| : qq|$stmt where $clause|;
	}elsif(ref($clause) =~ /^array$/i) {
		@bind = @{$clause};
	}
	my @data = ();
	eval{
		my $sth = $self->{_DB_HANDLE}->prepare($stmt);
		$sth->execute(@bind);
		while(my $reference = $sth->fetchrow_hashref()) {
			push(@data, $reference);
		}
		$sth->finish();	
	};
	if($@) {
		push(@{$self->{_ERROR_STORE}}, $@);
	}
	return @data;
}

sub commit {
	my ($self, $keep_connection_active) = @_;
	if($self->error()) {
		$self->{_DB_HANDLE}->rollback();
	}else {
		$self->{_DB_HANDLE}->commit();
		$self->{_ERROR_STORE} = [];
	}
	$self->{_DB_HANDLE}->disconnect() unless $keep_connection_active;
}

sub execute_stmt {
	my ($self, $stmt, $bind) = @_;
	$self->_sql_execute($stmt, $bind);
}

sub _sql_execute {
	my ($self, $stmt, $bind) = @_;
	eval{
		my $cnt = $self->{_DB_HANDLE}->do($stmt, undef, @{$bind});
		if($stmt =~ /^insert/i) {
			my @data = _sql_fetch($self, "select last_insert_id() AS 'id'");
			$self->{_INSERT_ID} = $data[0]->{id};
		}
		};
	if($@) {
		push(@{$self->{_ERROR_STORE}}, $@);
	}
}

sub handle { return $_[0]->{_DB_HANDLE}; }

sub DESTROY { $_[0]->{_DB_HANDLE}->disconnect() if(defined $_[0]->{_DB_HANDLE}); }

sub error_string {
	my $self = shift();
	return join("\n", @{$self->{_ERROR_STORE}});
}

sub re_set_errors {
	my ($self, $errors) = @_;
	@{$self->{_ERROR_STORE}} = @{$errors};
}

sub add_error {
	my ($self, $string) = @_;
	push(@{$self->{_ERROR_STORE}}, $string);
}

sub error {
	my $self = shift();
	return @{$self->{_ERROR_STORE}} ? 1 : 0;
}

# probably a primary key
sub key() { return $_[0]->{_INSERT_ID}; }

1;
