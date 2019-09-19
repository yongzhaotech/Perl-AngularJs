#! /usr/bin/perl
use strict;
use warnings;
use Class::Initialize;
use Class::Language;
use Class::Utility qw(j_son_js);

my $init = new Class::Initialize();
$init->apr()->content_type("text/html");
if($init->user_signed_in()) {
	$init->cookie()->delete('session_id');
	$init->session()->delete();
	print $init->toolkit('load_page')->string({ page => '' });
}else {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js([LANG_LABELS->{sign_outed}->{$init->cookie()->get('lang')}]) });
}
return Apache2::Const::OK
