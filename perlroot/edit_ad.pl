#! /usr/bin/perl
use strict;
use warnings;
use Class::Email;
use Class::Initialize;
use Class::Advertise;
use Class::Time;
use Class::Utility qw(trim format_message valid_phone valid_email upload_ad_image queue_ad_image no_accent html_name valid_token j_son_js);
use Class::Language;

my $init = new Class::Initialize();
my $lang = $init->lang();
$init->apr()->content_type("text/html");
if(!$init->success()) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js([LANG_LABELS->{re_sign_in}->{$lang}]) });
	return Apache2::Const::OK
}
my $cgi			= $init->cgi();
my $id			= trim($cgi->param('advertise_id'));
my $category_id = trim($cgi->param('category'));
my $item_id		= trim($cgi->param('item'));
my $name		= trim($cgi->param('ad_name'));
my $email		= lc(trim($cgi->param('contact_email')));
my $phone		= trim($cgi->param('contact_phone'));
my $is_free		= trim($cgi->param('is_free')); 
my $price		= trim($cgi->param('price')); 
my $currency	= trim($cgi->param('currency')); 
my $description	= trim($cgi->param('description')); 
my $address		= trim($cgi->param('address'));
my $main_pict	= trim($cgi->param('main_picture_id')); 
my $contact_method = trim($cgi->param('contact_method'));
my $province	= trim($cgi->param('province'));
my $city		= trim($cgi->param('city'));
my $rem_p_ids	= trim($cgi->param('remove_ad_image'));
my $token		= trim($init->cgi()->param('token'));

if(!valid_token($init->sql(), $token)) {
	print '';
	return Apache2::Const::OK
}

my $files	= {};
my @error	= ();
my $reply	= undef;
my $temp	= undef;

if($category_id eq '') {
	push(@error, LANG_LABELS->{r_category}->{$lang});
}
if($item_id eq '') {
	push(@error, LANG_LABELS->{r_item}->{$lang});
}
if($name eq '') {
	push(@error, LANG_LABELS->{r_ad_name}->{$lang});
}
if($is_free eq '') {
	push(@error, LANG_LABELS->{r_is_free}->{$lang});
}
if($contact_method eq '') {
	push(@error, LANG_LABELS->{r_contact_method}->{$lang});
}else {
	if($contact_method =~ /\bcontact_phone\b/ && !valid_phone($phone)) {
		push(@error, LANG_LABELS->{w_contact_phone}->{$lang});
	}
}
if($province eq '') {
	push(@error, LANG_LABELS->{r_province}->{$lang});
}
if($city eq '') {
	push(@error, LANG_LABELS->{r_city}->{$lang});
}

my $pictures = {};
foreach($cgi->param()) {
	if($_ =~ m/^ad_image_(\d+)$/ && length(trim($cgi->param($_)))) {
		$pictures->{$1} = {
			file => $_,
			name => "name_$1"
		}
	}
}
my $queue = (keys %{$pictures}) ? queue_ad_image($init, $pictures) : undef;
push(@error, @{$queue->{error}}) if(defined $queue && exists($queue->{error}));

if(!@error) {
	# continue.....
	# insert ad then insert pictures if they exist
	# remove pictures if selected
	if($rem_p_ids) {
		my $user_pict = {};
		foreach($init->sql()->query('select', qq|select p.id "id" from picture p,advertise a where p.advertise_id=a.id and a.id=? and a.user_id=?|, [$id, $init->user()->get('id')])) {
			$user_pict->{$_->{id}} = 1;
		}
		foreach(split(/,/, $rem_p_ids)) {
			if(exists($user_pict->{$_})) {
				$init->sql()->query('delete', 'picture', { id => $_});
				$files->{$_} = 1;
			}
		}
	}

	my $time = new Class::Time();
	my $now = $time->call('international');
	my $advertise = {
		category_id => $category_id,
		item_id => $item_id,
		name => $name,
		s_name => no_accent($name),
		is_free => $is_free,
		price => $price,
		currency => $currency,
		description => $description,
		s_description => no_accent($description),
		contact_method => $contact_method,
		contact_phone => $phone,
		contact_email => $email,
		address => $address,
		city_id => $city,
		province_id => $province
	};
	$advertise->{html} = html_name($id, $advertise->{s_name});
	$init->sql()->query('update', 'advertise', { id => $id, user_id => $init->user()->get('id') }, $advertise);
	my $image_queue = {};
	my $main_picture_id = undef;
	if(defined $queue && exists($queue->{image})) {
		foreach my $num (@{$queue->{image}}) {
			my $picture = {
				advertise_id => $id,
				name => trim($cgi->param('image_name_'.$num)),
				create_time => $now,
				edit_time => $now
			};
			$init->sql()->query('insert', 'picture', {}, $picture);
			$image_queue->{$num} = $init->sql()->key(); # associate the image number with the picture.id
			if($main_pict eq $num) {
				$main_picture_id = $init->sql()->key();
			}			
		}
	}
	if(!defined $main_picture_id) {
		if($main_pict && $main_pict =~ /^p(\d+)$/) {
			$main_picture_id = $1;
		}
	}
	$init->sql()->query('update', 'picture', { advertise_id => $id }, { is_main => 0 });
	$init->sql()->query('update', 'picture', { id => $main_picture_id }, { is_main => 1 }) if(defined $main_picture_id);
	upload_ad_image($init, $image_queue);
	foreach(keys %{$files}) {
		my $small = $init->config('small_image').'/'.$_.'.jpg';
		my $big = $init->config('big_image').'/'.$_.'.jpg';
		`rm $small`;
		`rm $big`;
	}
	$init->delete_advertise();
	$init->generate_html($id);
	$init->sql()->execute_stmt("delete from server_token where token=?", [$token]);
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}
}
	
if(@error) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
}else {
	print $init->toolkit('ng_post_confirm')->string({ server_response => j_son_js([LANG_LABELS->{c_ad_edit_ok}->{$lang}]), server_response_2 => $id });
}
return Apache2::Const::OK
