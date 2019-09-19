#! /usr/bin/perl

use warnings; 
use strict;
use lib qw(/home/laoye/sites/advertise/lib);
use Class::SQL;

my $sql = new Class::SQL;

$sql->query('delete', 'category');
$sql->query('delete', 'item');
my $cn = 0;
my $data = {};
open(R,"/home/laoye/sites/advertise/category");
while(<R>) {
	chomp;
	next if($_ =~ /^\~/);
	$_ =~ s/\r\n//g;
	my @data = split(/,/, $_);
	my ($en, $cn) = split(/::/, $_);
	my @data_en = split(/,/, $en);
	my @data_cn = split(/,/, $cn);
	my $category_en = shift(@data_en);
	my $category_cn = shift(@data_cn);
	$sql->query('insert', 'category', {}, { name => $category_en, name_cn => $category_cn });
	my $category_id = $sql->key();
	for(my $i = 0; $i < scalar(@data_en); $i++) {
		$sql->query('insert', 'item', {}, { category_id => $category_id, name => $data_en[$i], name_cn => $data_cn[$i], category_name => $category_en, category_name_cn => $category_cn });
	}
}
close(R);
$sql->commit();

