#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Language;
use Class::Utility qw(j_son_js);

my $init	= new Class::Initialize();
$init->apr()->content_type("application/json");
if(!$init->success()) {
	print qq|{"error":|.j_son_js([$init->error()]).qq|}|;
	return Apache2::Const::OK
}

open(W, " >/home/laoye/sites/advertise/webroot/html/sitemap.txt");
my $sql	= $init->sql();
my $sth = $sql->handle()->prepare("select id from advertise");
$sth->execute();
while(my ($id) = $sth->fetchrow_array()) {
	$init->delete_advertise();
	$init->generate_html($id);
	print W "http://esaleshome.com/ads/index.html#!/ad_detail/$id\n";
}
close(W);

print qq|{"ok":|.j_son_js(['Static html files generated!']).qq|}|;
return Apache2::Const::OK
