#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Language;
use Class::Utility qw(j_son_js);
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

my $init	= new Class::Initialize();
$init->apr()->content_type("application/json");
if(!$init->success()) {
	print qq|{"error":|.j_son_js([$init->error()]).qq|}|;
	return Apache2::Const::OK
}

open(V, "> /home/laoye/sites/advertise/webroot/library/jscript/langs.js") or die $!;
my $langs = LANG_LABELS;
my @labels = ();
foreach my $label (keys %{$langs}) {
	my @langs = ();
	foreach my $lang (keys %{$langs->{$label}}) {
		my $text = $langs->{$label}->{$lang};
		$text =~ s/'/\\'/g;
		push(@langs, qq|$lang:'$text'|);
	}
	push(@labels, qq|$label:{${\join(",",@langs)}}|);
}
print V qq|var lang_messages={${\join(",",@labels)}};|;
close(V);

my $sql	= $init->sql();
my $content = '';
my $path = '/home/laoye/sites/advertise/lib/Class/Content.pm';
my $js_path = '/home/laoye/sites/advertise/webroot/library/jscript/static_vars.js';
open(W, "> $path") or die $!;
open(J, "> $js_path") or die $!;
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
	select c.id as 'cat_id',c.name as 'cat_name',c.name_cn as 'cat_name_cn',i.id as 'i_id',i.name as 'i_name',i.name_cn as 'i_name_cn'
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
my $js = qq|var page_vars={};page_vars['search_seq']={province:1,city:2,category:3,item:4,ad_keyword:5};page_vars['category']=[|;

my $conf = ($sql->query('select', 'site_config', { site => 'advertise' }))[0];
$content .= "\t\tsite_config => ".Dumper($conf).",\n" if(defined $conf);
my $auth = {};
foreach($sql->query('select', 'site_authenticate', { site => 'advertise' })) {
	$auth->{$_->{page}} = $_;
}
$content .= "\t\tsite_authenticate => ".Dumper($auth).",\n" if(defined $auth);
foreach($sql->query('select', $stmt)) {
	$categories->{$_->{cat_id}} = { name_en => $_->{cat_name}, name_cn => $_->{cat_name_cn} };
	push(@{$items->{$_->{cat_id}}}, { id => $_->{i_id}, name_en => $_->{i_name}, name_cn => $_->{i_name_cn} });
	$all_items->{$_->{i_id}} = { name_en => $_->{i_name}, name_cn => $_->{i_name_cn} };
}
foreach(keys %{$items}) {
	unshift(@{$items->{$_}},  { id => '', name_en => 'sub categories under '.$categories->{$_}->{name_en}, name_cn => $categories->{$_}->{name_cn}.'分类' });
}
my @categories = map({ id => $_, name_en => $categories->{$_}->{name_en}, name_cn => $categories->{$_}->{name_cn} }, sort { $categories->{$a} cmp $categories->{$b} } keys %{$categories});
unshift(@categories,  { id => '', name_en => 'Category', name_cn => '总类' });
foreach my $cat_ref (@categories) {
	my $cat_id = $cat_ref->{id};
	$cat_ref->{name_en} =~ s/'/\\'/g;
	$cat_ref->{name_cn} =~ s/'/\\'/g;
	$js .= qq|{n:{en:'$cat_ref->{name_en}',cn:'$cat_ref->{name_cn}'},i:'$cat_id',c:[|;
	foreach my $item (@{$items->{$cat_id}}) {
		$item->{name_en} =~ s/'/\\'/g;
		$item->{name_cn} =~ s/'/\\'/g;
		$js .= qq|{i:'$item->{id}',n:{en:'$item->{name_en}',cn:'$item->{name_cn}'}},|;
	}
	$js =~ s/,$//;
	$js .= "]},";
}
$js =~ s/,$//;
$js .= qq|];|;

$js .= qq|page_vars['province']=[|;
$stmt = qq|
	select p.id as 'p_id',p.province as 'p_name',p.province_cn as 'p_name_cn',p.country as 'p_country',p.country_cn as 'p_country_cn',c.id as 'c_id',c.city as 'c_name',c.city_cn as 'c_name_cn'
	from province p,city c
	where p.id=c.province_id
	order by p.country,p.province,c.city
|;
my $states = {};
my $provinces = {};
my $countries = {};
my $cities = {};
my $all_cities = {};
foreach($sql->query('select', $stmt)) {
	$states->{$_->{p_id}} = { country_en => $_->{p_country}, country_cn => $_->{p_country_cn} };
	push(@{$countries->{$_->{p_country}}}, { id => $_->{p_id}, name_en => $_->{p_name}, name_cn => $_->{p_name_cn} }) if(!exists($provinces->{$_->{p_id}}));
	$provinces->{$_->{p_id}} = { name_en => $_->{p_name}, name_cn => $_->{p_name_cn} };
	push(@{$cities->{$_->{p_id}}}, { id => $_->{c_id}, name_en => $_->{c_name}, name_cn => $_->{c_name_cn} });
	$all_cities->{$_->{c_id}} = { name_en => $_->{c_name}, name_cn => $_->{c_name_cn} };
}
foreach(keys %{$cities}) {
	unshift(@{$cities->{$_}}, { name_en => 'major cities / towns in '.$provinces->{$_}->{name_en}, name_cn => $provinces->{$_}->{name_cn}.'中的主要城镇', id => '' });
}

$content .= "\t\tall_provinces => ".Dumper($provinces).",\n";
$content .= "\t\tall_cities => ".Dumper($all_cities).",\n";
$content .= "\t\tall_categories => ".Dumper($categories).",\n";
$content .= "\t\tall_items => ".Dumper($all_items).",\n";

my @provinces = ({ id => '', name_en => 'Province / State', name_cn => '加拿大省或美国州' });
foreach my $country (sort { $a cmp $b } keys %{$countries}) {
	my @arr = sort { $a->{name_en} cmp $b->{name_en} } @{$countries->{$country}};
	push (@provinces, @arr);
}
foreach my $prov (@provinces) {
	my $p_id = $prov->{id};
	$prov->{name_en} =~ s/'/\\'/g;
	$prov->{name_cn} =~ s/'/\\'/g;
	$js .= qq|{s:{en:'$states->{$p_id}->{country_en}',cn:'$states->{$p_id}->{country_cn}'},n:{en:'$prov->{name_en}',cn:'$prov->{name_cn}'},i:'$p_id',c:[|;
	foreach my $city (@{$cities->{$p_id}}) {
		$city->{name_en} =~ s/'/\\'/g;
		$city->{name_cn} =~ s/'/\\'/g;
		$js .= qq|{i:'$city->{id}',n:{en:'$city->{name_en}',cn:'$city->{name_cn}'}},|;
	}
	$js =~ s/,$//;
	$js .= "]},";
}
$js =~ s/,$//;
$js .= qq|];|;

$content .= "\t};\n\n";
$content .= "\treturn \$content->{\$key};\n";
$content .= "}\n\n";
$content .= "return 1;";
print W $content;
print J $js;
close(W);
close(J);
`chmod 777 $path`;

print qq|{"ok":|.j_son_js(['Static content file generated!']).qq|}|;

return Apache2::Const::OK
