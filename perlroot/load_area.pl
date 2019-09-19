#! /usr/bin/perl

use warnings; 
use strict;
use lib qw(/home/laoye/sites/advertise/lib);
use Class::SQL;

my $sql = new Class::SQL;

$sql->query('delete', 'province');
$sql->query('delete', 'city');

open(R,"/home/laoye/sites/advertise/ca_city");
while(<R>) {
	chomp;
	$_ =~ s/[\r\n]//g;
	my ($en, $cn) = split(/::/, $_);
	my @data_en = split(/,/, $en);
	my @data_cn = split(/,/, $cn);
	my $province_en = shift(@data_en);
	my $province_cn = shift(@data_cn);
	$sql->query('insert', 'province', {}, { province => $province_en, country => 'Canada', province_cn => $province_cn, country_cn => '加拿大' });
	my $province_id = $sql->key();
	for(my $i = 0; $i < scalar(@data_en); $i++) {
		$sql->query('insert', 'city', {}, { province_id => $province_id, city => $data_en[$i], province => $province_en, country => 'Canada', city_cn => $data_cn[$i], province_cn => $province_cn, country_cn => '加拿大' });
	}
}
close(R);

open(R,"/home/laoye/sites/advertise/us_city");
while(<R>) {
	chomp;
	$_ =~ s/[\r\n]//g;
	my ($en, $cn) = split(/::/, $_);
	my @data_en = split(/,/, $en);
	my @data_cn = split(/,/, $cn);
	my $province_en = shift(@data_en);
	my $province_cn = shift(@data_cn);
	$sql->query('insert', 'province', {}, { province => $province_en, country => 'USA', province_cn => $province_cn, country_cn => '美国' });
	my $province_id = $sql->key();
	for(my $i = 0; $i < scalar(@data_en); $i++) {
		$sql->query('insert', 'city', {}, { province_id => $province_id, city => $data_en[$i], province => $province_en, country => 'USA', city_cn => $data_cn[$i], province_cn => $province_cn, country_cn => '美国' });
	}
}
close(R);

$sql->commit();

