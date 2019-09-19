package Class::Toolkit;

use Template;
our @ISA = ("Template");

# constructor
sub new {
	my ($object, $source, $init) = @_;
	my $class = ref($object) || $object;
	my $self = $class->SUPER::new({
		INCLUDE_PATH	=> "${\$init->config('toolkit_src')}:${\$init->config('toolkit_lib')}",
		LOAD_PERL		=> 1, # programmer-defined class objects can be used as pluggins
		EVAL_PERL		=> 1, # enable perl codes to be embedded 
		ANYCASE			=> 1,		
		TRIM			=> 1,
		PRE_CHOMP		=> 2,
		POST_CHOMP		=> 2
	});
	$self->{_SOURCE} = $source;
	$self->{_SITE_CONFIG} = $init;
	return bless($self, $object);
}

sub output {
	# $param - hash reference
	my ($self, $params) = @_;
	$params->{site_config} = $self->{_SITE_CONFIG};
	$self->process($self->{_SOURCE},$params);
}

sub string {
	# $param - hash reference
	my ($self, $params) = @_;
	$params->{site_config} = $self->{_SITE_CONFIG};
	my $string = "";
	eval{
		$self->process($self->{_SOURCE},$params,\$string);
	};
	return $self->error() ? $self->error() : $string;
}

sub print_out {
	my ($self, $params) = @_;
	$params->{site_config} = $self->{_SITE_CONFIG};
	print $self->string($params);
}

1;
