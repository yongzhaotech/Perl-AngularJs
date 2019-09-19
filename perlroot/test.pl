#!/usr/bin/perl
use warnings;
use strict;

my $A = "abcdefg";
my @A = split(//, $A);
print "Length of $A is: ".length($A)."\n";

my $B = "中国共产党万岁";
my @B = split(//, $B);
print "Length of $B is: ".length($B)."\n";
