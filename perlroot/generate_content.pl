#! C:/Perl/bin/perl.exe

use warnings; 
use strict;
use lib qw(/home/laoye/sites/advertise/lib/);

use Class::SQL;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

my $sql	= new Class::SQL();
my $content = '';
my $reply	= undef;
my $temp	= undef;
my $path = '../lib/Class/Content.pm';
open(W, "> $path");
$content .= "package Class::Content;\n\n";
$content .= "
use vars qw(\@ISA \@EXPORT);
use Exporter;

\@ISA = qw(Exporter);
\@EXPORT = qw(
	static_content
);\n\n
";
my $stmt = qq|
	select c.id as 'cat_id',c.name as 'cat_name',i.id as 'i_id',i.name as 'i_name'
	from category c,item i
	where c.id=i.category_id
	order by c.name,i.name
|;

$content .= "sub static_content {\n";
$content .= "\t\$key = shift();\n";
$content .= "\tmy \$content = {\n";
my $categories = {};
my $items = {};
my $all_items = {};
my $js = '';

my $conf = ($sql->query('select', 'site_config', { site => 'advertise' }))[0];
$content .= "\t\tsite_config => ".Dumper($conf).",\n" if(defined $conf);
my $auth = {};
foreach($sql->query('select', 'site_authenticate', { site => 'advertise' })) {
	$auth->{$_->{page}} = $_;
}
$content .= "\t\tsite_authenticate => ".Dumper($auth).",\n" if(defined $auth);
foreach($sql->query('select', $stmt)) {
	$categories->{$_->{cat_id}} = $_->{cat_name};
	push(@{$items->{$_->{cat_id}}}, { id => $_->{i_id}, name => $_->{i_name} });
	$all_items->{$_->{i_id}} = $_->{i_name};
}
foreach(keys %{$items}) {
	unshift(@{$items->{$_}},  { id => '', name => 'All Categories' });
}
my @categories = sort { $a->{name} cmp $b->{name} } map({ id => $_, name => $categories->{$_} }, keys %{$categories});
$content .= "\t\tcategories => ".Dumper(\@categories).",\n";
my @items = sort { $a->{name} cmp $b->{name} } @{$items->{$categories[0]->{id}}}; # first category is selected by default
$content .= "\t\titems  => ".Dumper(\@items).",\n";
foreach my $cat_ref (@categories) {
	my $cat_id = $cat_ref->{id};
	$js .= "page_vars['category']['$cat_id']=[";
	foreach my $item (@{$items->{$cat_id}}) {
		$item->{name} =~ s/'/\\\\\\'/g;
		$js .= "{i:'$item->{id}',n:'$item->{name}'},";
	}
	$js =~ s/,$//;
	$js .= "];";
	$js =~ s/"/\\\\\\"/g;
}
$content .= qq|\t\tcategory_js => "$js",\n|;

$js = '';
$stmt = qq|
	select p.id as 'p_id',p.province as 'p_name',c.id as 'c_id',c.city as 'c_name'
	from province p,city c
	where p.id=c.province_id
	order by c.city
|;
my $provinces = {};
my $cities = {};
my $all_cities = {};
$js = '';
foreach($sql->query('select', $stmt)) {
	$provinces->{$_->{p_id}} = $_->{p_name};
	push(@{$cities->{$_->{p_id}}}, { id => $_->{c_id}, name => $_->{c_name} });
	$all_cities->{$_->{c_id}} = $_->{c_name};
}
foreach(keys %{$cities}) {
	unshift(@{$cities->{$_}}, { name => 'All Cities', id => '' });
}

$content .= "\t\tall_provinces => ".Dumper($provinces).",\n";
my @provinces = sort { $a->{name} cmp $b->{name} } map({ id => $_, name => $provinces->{$_} }, keys %{$provinces});
$content .= "\t\tprovinces => ".Dumper([{ id => '', name => 'All Provinces' }, @provinces]).",\n";
$content .= "\t\tcities  => ".Dumper($cities).",\n";
$content .= "\t\tall_cities => ".Dumper($all_cities).",\n";
$content .= "\t\tall_categories => ".Dumper($categories).",\n";
$content .= "\t\tall_items => ".Dumper($all_items).",\n";
foreach my $prov (@provinces) {
	my $p_id = $prov->{id};
	$js .= "page_vars['province']['$p_id']=[";
	foreach my $city (@{$cities->{$p_id}}) {
		$city->{name} =~ s/'/\\\\\\'/g;
		$js .= "{i:'$city->{id}',n:'$city->{name}'},";
	}
	$js =~ s/,$//;
	$js .= "];";
	$js =~ s/"/\\\\\\"/g;
}
$content .= qq|\t\tprovince_js => "$js",\n|;
$content .= "\t};\n\n";
$content .= "\treturn \$content->{\$key};\n";
$content .= "}\n\n";
$content .= "return 1;";
print W $content;
close(W);

