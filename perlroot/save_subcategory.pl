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

if($action eq 'new_subcategory') {
	my $time = new Class::Time();
	my $now = $time->call('international');
	my $category_id = trim($cgi->param('category'));
	my $sub_category_name = trim($cgi->param('sub_category'));
	my $sub_category_name_cn = trim($cgi->param('sub_category_cn'));
	if($sub_category_name eq '' || $sub_category_name_cn eq '' || $category_id eq '') {
		push(@error, "Information is missing");
	}
	if(!@error) {
		my $category = ($init->sql()->query('select', 'category', { id => $category_id }))[0];
		my $category_name = $category->{name};
		my $category_name_cn = $category->{name_cn};
		
		$init->sql()->query('insert', 'item', {}, { name => $sub_category_name, name_cn => $sub_category_name_cn, create_time => $now, category_id => $category_id, category_name => $category_name, category_name_cn => $category_name_cn });
		$init->sql()->commit();
		if($init->sql()->error()) {
			push(@error, $init->sql()->error_string());
		}
	}	
}elsif($action eq 'edit_subcategory') {
	my $id = trim($cgi->param('item'));
	my $name = trim($cgi->param('new_subcategory'));
	my $name_cn = trim($cgi->param('new_subcategory_cn'));
	if($name eq '' || $name_cn eq '' || $id eq '') {
		push(@error, "Sub category information is missing");
	}
	if(!@error) {
		$init->sql()->query('update', 'item', { id => $id }, { name => $name, name_cn => $name_cn });
	}
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}
}

if(@error) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
}else {
	print $init->toolkit('load_page')->string({ page => '#!/save_subcategory' });
}
return Apache2::Const::OK
