#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Utility qw(trim j_son_js);
use Class::Time;

my $init = new Class::Initialize();

$init->apr()->content_type("text/html");
if(!$init->success()) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js([$init->error()]) });
	return Apache2::Const::OK
}

my $cgi		= $init->cgi();
my $action	= trim($cgi->param('frm_action'));

my @error	= ();
my $reply	= undef;
my $temp	= undef;

if($action eq 'new_category') {
	my $time = new Class::Time();
	my $now = $time->call('international');
	my $category_name = trim($cgi->param('new_category'));
	my $category_name_cn = trim($cgi->param('new_category_cn'));
	if($category_name eq '') {
		push(@error, "Enter category text");
	}
	if($category_name_cn eq '') {
		push(@error, "Enter category Chinese text");
	}
	if(!@error) {
		$init->sql()->query('insert', 'category', {}, { name => $category_name, create_time => $now, name_cn => $category_name_cn });
		$init->sql()->commit();
		if($init->sql()->error()) {
			push(@error, $init->sql()->error_string());
		}
	}	
}elsif($action eq 'edit_category') {
	my $category_name = trim($cgi->param('new_category'));
	my $category_name_cn = trim($cgi->param('new_category_cn'));
	my $category_id = trim($cgi->param('category'));
	if($category_name eq '' || $category_name_cn eq '' || $category_id eq '') {
		push(@error, "Category information is missing");
	}
	if(!@error) {
		$init->sql()->query('update', 'category', { id => $category_id }, { name => $category_name, name_cn => $category_name_cn });
		$init->sql()->query('update', 'item', { category_id => $category_id }, { category_name => $category_name, category_name_cn => $category_name_cn });
		$init->sql()->commit();
		if($init->sql()->error()) {
			push(@error, $init->sql()->error_string());
		}
	}
}

if(@error) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
}else {
	print $init->toolkit('load_page')->string({ page => '#!/save_category' });
}
return Apache2::Const::OK
