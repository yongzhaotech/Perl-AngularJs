package Class::Time;

sub new {
    my $object = shift();
    my $class  = ref($object) || $object;
    my $self   = {error => sub {return "The called function $_[0] is not defined";}};
	my ($second, $minute, $hour, $day, $month, $year, $dow) = (localtime)[0..6];
	$dow = 7 if($dow == 0);
	$$self{second} = sprintf "%02d", $second;
	$$self{minute} = sprintf "%02d", $minute;
	$$self{hour}   = sprintf "%02d", $hour;
	$$self{day}    = sprintf "%02d", $day;
	$$self{month}  = sprintf "%02d", $month + 1;
	$$self{year}   = sprintf "%04d", $year + 1900;
	$$self{dow}	   = day_of_week($dow); # Chars 
	$$self{_DOW}   = $dow; # digits

    $$self{'international'} = sub {
		return "$$self{year}-$$self{month}-$$self{day} $$self{hour}:$$self{minute}:$$self{second}";
	};
	$$self{'america'} = sub {
		# implemented later
		return "${\month_char($$self{month})} $$self{day}, $$self{year}";
	};
	$$self{'business_time'} = sub {
		return "$$self{dow} ${\month_char($$self{month})} $$self{day}, $$self{year} $$self{hour}:$$self{minute}";
	};
	$$self{'business_date'} = sub {
		return "$$self{dow} ${\month_char($$self{month})} $$self{day}, $$self{year}";
	};
	$$self{'hh_mm_ss'} = sub {
		return "$$self{hour}:$$self{minute}:$$self{second}";
	};
    return bless($self, $class);
}

sub call {
    my ($self, $callee) = @_;
    return defined $$self{lc($callee)} ? $$self{lc($callee)}->() : $$self{error}->($callee);
}

sub year {
	my $self = shift();
	return $$self{year};
}

sub month {
    my $self = shift();
	return $$self{month};
}

sub day {
    my $self = shift();
	return $$self{day};
}

sub hour {
	my $self = shift();
	return $$self{hour};
}

sub minute {
	my $self = shift();
	return $$self{minute};
}

sub second {
	my $self = shift();
	return $$self{second};
}

# return the digital day of week
sub dow {
	my $self = shift();
	return $$self{_DOW};
}

sub month_char {
	my $chars = {
		"01" => "Jan",
		"02" => "Feb",
		"03" => "Mar",
		"04" => "Apr",
		"05" => "May",
		"06" => "Jun",
		"07" => "Jul",
		"08" => "Aug",
		"09" => "Sept",
		"10" => "Oct",
		"11" => "Nov",
		"12" => "Dec"
	};
	return $chars->{shift()};
}

sub day_of_week {
	my $chars = {
		1 => "Mon.",
		2 => "Tue.",
		3 => "Wed.",
		4 => "Thu.",
		5 => "Fri.",
		6 => "Sat.",
		7 => "Sun."
	};
	return $chars->{shift()};
}

return 1;

