#! /usr/bin/perl
use strict;
use warnings;
use Class::Email;
use Class::Initialize;
use Class::Advertise;
use Class::Time;
use Class::Utility qw(trim valid_phone valid_email upload_ad_image queue_ad_image unique_id no_accent html_name valid_token j_son_js j_son);
use Class::Language;

my $init = new Class::Initialize();
my $lang = $init->lang();
$init->apr()->content_type("text/html");

if(!$init->success()) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js(["Something gets wrong"]) });
	return Apache2::Const::OK
}

my $cgi			= $init->cgi();
my $category_id = trim($cgi->param('category'));
my $item_id		= trim($cgi->param('item'));
my $name		= trim($cgi->param('ad_name'));
my $phone		= trim($cgi->param('contact_phone'));
my $email		= lc(trim($cgi->param('email')));
my $is_free		= trim($cgi->param('is_free')); 
my $price		= trim($cgi->param('price')); 
my $currency	= trim($cgi->param('currency')); 
my $description	= trim($cgi->param('description')); 
my $address		= trim($cgi->param('address'));
my $main_pict	= trim($cgi->param('main_picture_id')); 
my $contact_method = trim($cgi->param('contact_method'));
my $province	= trim($cgi->param('province'));
my $city		= trim($cgi->param('city'));
my $parent_form = trim($cgi->param('p_f_name'));
my $token = trim($init->cgi()->param('token'));

if(!valid_token($init->sql(), $token)) {
	print '';
	return Apache2::Const::OK
}

my @error	= ();
my $reply	= undef;
my $temp	= undef;
my $post_id	= undef;

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
	if($contact_method =~ /\bemail\b/ && !valid_email($email)) {
		push(@error, LANG_LABELS->{w_email}->{$lang});
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

my $lnk_id = '';

if(!@error) {
	# continue.....
	# insert ad then insert pictures if they exist
	my $time = new Class::Time();
	my $now = $time->call('international');
	$post_id = $init->user_signed_in() ? '' : substr(unique_id(), 0, 8);
	my $advertise = {
		user_id	=> $init->user_signed_in() ? $init->user()->get('id') : 0,
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
		main_picture_id => $main_pict,
		address => $address,
		city_id => $city,
		province_id => $province,
		active => 1,
		create_time => $now,
		post_id => $post_id
	};
	$init->sql()->query('insert', 'advertise', {}, $advertise);
	my $advertise_id = $init->sql()->key();
	$lnk_id = $advertise_id;
	$init->sql()->execute_stmt("update advertise set html=? where id=?", [html_name($advertise_id, $advertise->{s_name}), $advertise_id]);
	my $image_queue = {};
	if(defined $queue && exists($queue->{image})) {
		foreach my $num (@{$queue->{image}}) {
			my $picture = {
				advertise_id => $advertise_id,
				name => trim($cgi->param('image_name_'.$num)),
				is_main => $main_pict eq $num ? 1 : 0,
				create_time => $now,
				edit_time => $now
			};
			$init->sql()->query('insert', 'picture', {}, $picture);
			$image_queue->{$num} = $init->sql()->key(); # associate the image number with the picture.id
		}
	}
	upload_ad_image($init, $image_queue);
	$init->generate_html($advertise_id);
	$init->sql()->execute_stmt("delete from server_token where token=?", [$token]);
	$init->sql()->commit();
	if($init->sql()->error()) {
		push(@error, $init->sql()->error_string());
	}
}
	
if(@error) {
	print $init->toolkit('ng_errors')->string({ server_response => j_son_js(\@error) });
}else {
	my $msgs = ["[ $name ] ".LANG_LABELS->{ad_added}->{$lang}."!"];
	if($post_id) {
		my $info = {};
		$info->{phone} = $phone if($phone);
		$info->{email} = $email if($email);
		my $remember = LANG_LABELS->{remember}->{$lang};
		push(@{$msgs}, $remember.':');
		my $p_id = LANG_LABELS->{post_id}->{$lang};
		my $items = join(", ", map(LANG_LABELS->{$_}->{$lang}.qq|: $info->{$_}|, keys %{$info}));
		push(@{$msgs}, "$p_id: $post_id");
		push(@{$msgs}, $items);
	}
	print $init->toolkit('ng_post_confirm')->string({ server_response => j_son_js($msgs), server_response_2 => $lnk_id });
}
return Apache2::Const::OK
