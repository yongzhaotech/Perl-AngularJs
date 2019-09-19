package Class::Utility;

use vars qw(@ISA @EXPORT);
use Exporter;
use Data::UUID;
use Digest::SHA;
use Text::Unaccent qw(unac_string);
use JSON::XS;
use Class::Content qw(static_content);
use Class::Language;

@ISA = qw(Exporter);
@EXPORT = qw(
	format_message
	get_token
	create_page_data
	create_advertise_data
	create_search_advertise_data
	create_ad_detail_data
	create_edit_ad_data
	create_admin_user_data
	create_admin_advertise_data
	create_page_permission_data
	create_admin_category
	create_admin_subcategory
	create_visitor_ad_data
	create_visitor_hits_data
	validate_acc_code
	queue_ad_image
	upload_ad_image
	unique_id
	no_accent
	trim
	is_nothing
	site_encryption
	url_encode
	url_decode
	is_something
	fields_not_blank
	page_selections
	monthChar
	dayOfWeek
	dateTimeData
	selectionData
	pageSelections
	validDollar
	formatDollar
	valid_email
	valid_phone
	js_clean
	html_name
	valid_token
	gen_token
	html_paragraph
	j_son
	j_son_js
);

sub format_message {
	my $msg_array = shift();
	return "<ul><li>".join("</li><li>", @{$msg_array})."</li></ul>";
}

sub get_token {
    my ($init) = @_;
    my $token = {};
    $token->{"is_${\$init->template()}"} = 1;
    $token->{include_template} = $init->template();
    $token->{message} = $init->error() if($init->template() eq 'error');
	$token->{language} = $init->{gen_html_language} || $init->cookie()->get('lang');
    # more code will be added in Class::Utility::create_page_data based on the $page
    create_page_data($init, $token);
    return $token;
}

sub create_page_data {
	my ($init, $page_data) = @_;
	if($init->template() =~ /^save_category$/) {
		foreach($init->sql()->query('select', 'select * from category order by name')) {
			push(@{$page_data->{categories}}, { id => $_->{id}, name => $_->{name}, name_cn => $_->{name_cn} });
		}
		return;
	}elsif($init->template() =~ /^save_subcategory$/) {
		my $js = '';
		foreach($init->sql()->query('select', 'select * from category order by name')) {
			push(@{$page_data->{categories}}, { id => $_->{id}, name => $_->{name}, name_cn => $_->{name_cn} });
		}
		my $items = {};
		foreach($init->sql()->query('select', qq|select * from item order by name|)) {
			push(@{$items->{$_->{category_id}}}, { id => $_->{id}, name => $_->{name}, name_cn => $_->{name_cn} });
		}
		$page_data->{items} = $items;
		my @cats = @{$page_data->{categories}};
		$page_data->{default_category_id} = $cats[0]->{id};
		foreach my $c_id (keys %{$items}) {
			$js .= "adm_page_vars['category']['$c_id']=[";
			foreach(@{$items->{$c_id}}) {
				$_->{name} =~ s/'/\\'/g;
				$_->{name_cn} =~ s/'/\\'/g;
				$js .= "{i:'$_->{id}',n:'$_->{name}',n_cn:'$_->{name_cn}'},";
			}
			$js =~ s/,$//;
			$js .= "];";
		}
		$page_data->{category_list} = $js;
		return;
	}
	eval("create_".$init->template()."_data(\$init, \$page_data)");
}

sub create_advertise_data {
	my ($init, $page_data, $additional_conditions) = @_;
	my $other_clause = '';
	my @clauses = ();
	my @bind = (1);
	my $start = defined $init->querystring() ? $init->querystring()->{start} || 0 : 0;
	my $size = $init->config('page_size');
	if(defined $additional_conditions) {
		if(exists($additional_conditions->{user_id})) {
			push(@clauses, "a.user_id=?");
			push(@bind, $additional_conditions->{user_id});
		}
		if(exists($additional_conditions->{advertise_id})) {
			push(@clauses, "a.id=?");
			push(@bind, $additional_conditions->{advertise_id});
		}
	}
	$other_clause = ' and '.join(' and ', @clauses) if(@clauses);
	my $stmt = qq|
		select a.id as 'id',a.name as 'name',a.html as 'html',a.address as 'address',a.description as 'description',a.is_free,a.currency,a.price,a.contact_method as 'contact_method',a.contact_email as 'contact_email',a.contact_phone as 'contact_phone',a.city_id as 'city_id',a.province_id as 'province_id',date(a.create_time) as 'create_date',a.item_id as 'item_id',a.category_id as 'category_id',a.viewed as 'viewed',p.ids as 'picture_ids'
		from advertise a left outer join (
			select advertise_id,group_concat(concat(id,' ',is_main,' ',edit_time) separator ',') as 'ids' from picture group by advertise_id
		) p
		on a.id=p.advertise_id
		where a.active=? $other_clause
		order by a.create_time desc
		limit $start,$size
	|;
	my $count_stmt = qq|
		select count(a.id) as 'total'
		from advertise a
		where a.active=? $other_clause
	|;
	
	my $sth = $init->sql()->handle()->prepare($stmt);
	$sth->execute(@bind);
	my $ng_pages = {};
	my $total = ($init->sql()->query('select', $count_stmt, \@bind))[0]->{total};
	page_selections($start, $size, $total, $ng_pages);
	while(my $ad = $sth->fetchrow_hashref()) {
		if($ad->{picture_ids} eq '') {
			$ad->{picture_id} = 0;
			$ad->{picture_ids} = [];
			$ad->{main_picture_id} = '';
		}else {
			my $pictures = {};
			my $main_picture_id = undef;
			my @picture_info = split(/\,/, $ad->{picture_ids});
			foreach my $picture (@picture_info) {
				my ($id, $is_main, $edit_time) = split(/ /, $picture);
				$main_picture_id = $id if($is_main);
				$pictures->{$id} = $edit_time;
			}
			my @pictures = sort { $pictures->{$b} cmp $pictures->{$a} } keys %{$pictures};
			if(!defined $main_picture_id) {
				$main_picture_id = $pictures[0];
			}
			$ad->{picture_id} = $main_picture_id;
			$ad->{picture_ids} = \@pictures;
			$ad->{number_of_pictures} = scalar(@pictures);
			$ad->{main_picture_id} = $main_picture_id;
		}
		$ad->{province} = { en => static_content('all_provinces')->{$ad->{province_id}}->{'name_en'}, cn => static_content('all_provinces')->{$ad->{province_id}}->{'name_cn'}, };
		$ad->{city} = { en => static_content('all_cities')->{$ad->{city_id}}->{'name_en'}, cn => static_content('all_cities')->{$ad->{city_id}}->{'name_cn'} };
		$ad->{price_display} = { en => LANG_LABELS->{'currency_'.$ad->{currency}}->{en}.$ad->{price}, cn => LANG_LABELS->{'currency_'.$ad->{currency}}->{cn}.$ad->{price} };
		push(@{$page_data->{advertises}}, $ad);
	}
	my $angular_ads = j_son($page_data->{advertises});
	my $angular_ad_pages = j_son($ng_pages);
	$page_data->{angular_ads} = $angular_ads;
	$page_data->{angular_ad_pages} = $angular_ad_pages;
	$page_data->{json} = qq|{"angular_ads":|.$angular_ads.",".qq|"angular_ad_pages":|.$angular_ad_pages."}";
}

sub create_ad_detail_data {
	my ($init, $page_data, $result) = @_;
	use Class::Advertise;
	my $query_string = $init->querystring();
	$init->advertise(new Class::Advertise($init->sql(), $init->cgi()->param('advertise_id')));
	if(!defined $init->advertise()) {
		return;
	}
	my @terms = ();
	my $desc = $init->advertise()->get('description');
	$desc =~ s/[\n]/<br>/g;
	$init->advertise()->set({ location => {en=>$init->advertise()->get('address'),cn=>$init->advertise()->get('address')} });
	$init->advertise()->set({ location => {en=>LANG_LABELS->{no_addr}->{en},cn=>LANG_LABELS->{no_addr}->{cn}} }) if(!$init->advertise()->get('address'));
	$init->advertise()->set({ ad_description => {en=>$desc,cn=>$desc} });
	$init->advertise()->set({ ad_description => {en=>LANG_LABELS->{r_no_description}->{en},cn=>LANG_LABELS->{r_no_description}->{cn}} }) if(is_nothing($init->advertise()->get('ad_description')));
	$init->advertise()->set({ province => {en=>static_content('all_provinces')->{$init->advertise()->get('province_id')}->{'name_en'},cn=>static_content('all_provinces')->{$init->advertise()->get('province_id')}->{'name_cn'}} });
	$init->advertise()->set({ city => {en=>static_content('all_cities')->{$init->advertise()->get('city_id')}->{'name_en'},cn=>static_content('all_cities')->{$init->advertise()->get('city_id')}->{'name_cn'}} });
	$init->advertise()->set({ category => {en=>static_content('all_categories')->{$init->advertise()->get('category_id')}->{'name_en'},cn=>static_content('all_categories')->{$init->advertise()->get('category_id')}->{'name_cn'}} });
	$init->advertise()->set({ item => {en=>static_content('all_items')->{$init->advertise()->get('item_id')}->{'name_en'},cn=>static_content('all_items')->{$init->advertise()->get('item_id')}->{'name_cn'}} });
	$init->advertise()->set({ price_display => {en=>LANG_LABELS->{'currency_'.$init->advertise()->get('currency')}->{en}.$init->advertise()->get('price'),cn=>LANG_LABELS->{'currency_'.$init->advertise()->get('currency')}->{cn}.$init->advertise()->get('price')} });
	$page_data->{advertise} = $init->advertise();
	push(@terms, { text => {en=>static_content('all_provinces')->{$init->advertise()->get('province_id')}->{'name_en'},cn=>static_content('all_provinces')->{$init->advertise()->get('province_id')}->{'name_cn'}}, key => 'province' });
	push(@terms, { text => {en=>static_content('all_cities')->{$init->advertise()->get('city_id')}->{'name_en'},cn=>static_content('all_cities')->{$init->advertise()->get('city_id')}->{'name_cn'}}, key => 'city' });
	push(@terms, { text => {en=>static_content('all_categories')->{$init->advertise()->get('category_id')}->{'name_en'},cn=>static_content('all_categories')->{$init->advertise()->get('category_id')}->{'name_cn'}}, key => 'category' });
	push(@terms, { text => {en=>static_content('all_items')->{$init->advertise()->get('item_id')}->{'name_en'},cn=>static_content('all_items')->{$init->advertise()->get('item_id')}->{'name_cn'}}, key => 'item' });
	push(@terms, { text => {en=>$init->advertise()->get('name'),cn=>$init->advertise()->get('name')}, key => 'ad_keyword' });
	$page_data->{search_item} = {
		pr => $init->advertise()->get('province_id'),
		ct => $init->advertise()->get('city_id'),
		ca => $init->advertise()->get('category_id'),
		it => $init->advertise()->get('item_id'),
		kw => $init->advertise()->get('name')	
	};
	$page_data->{search_item}->{kw} =~ s/'/\\'/g;
	$page_data->{search_terms} = j_son(\@terms);
	$page_data->{item} = j_son($page_data->{search_item});
	my $main_picture = $page_data->{advertise}->get('main_picture')->{id};
	my @pictures = map({i=>$_->{id}}, @{$page_data->{advertise}->get('pictures')});
	$page_data->{angular_ad} = j_son({
		main_picture=>$main_picture, 
		province=>$init->advertise()->get('province'),
		city=>$init->advertise()->get('city'),
		category=>$init->advertise()->get('category'),
		item=>$init->advertise()->get('item'),
		location=>$init->advertise()->get('location'),
		price_display=>$init->advertise()->get('price_display'),
		ad_description=>$init->advertise()->get('ad_description'),
		picture_ids=>\@pictures, 
		is_free=>$init->advertise()->get('is_free'),
		name=>$init->advertise()->get('name'),
		contact_phone=>$init->advertise()->get('contact_phone'),
		contact_method=>$init->advertise()->get('contact_method'),
		dtl=>1, 
		id=>$init->advertise()->get('id'),
		search_terms=>\@terms,
		item=>$page_data->{search_item}
	});
	$$result = 1;
}

sub create_admin_advertise_data {
	my ($init, $page_data, $result) = @_;
	my $start = $init->cgi()->param('start') || 0;
	my $size = $init->config('page_size');
	my $stmt = qq|
		select a.id as 'id',a.name as 'name',a.create_time as 'create_time',a.active as 'active',u.email as 'poster',a.contact_email as 'contact_email',a.contact_phone as 'contact_phone',a.post_id as 'post_id'
		from advertise a,user u
		where a.user_id=u.id
		order by a.create_time desc
		limit $start,$size
	|;
	my $count_stmt = qq|
		select count(a.id) as 'total'
		from advertise a,user u
		where a.user_id=u.id
	|;
	my @ads = $init->sql()->query('select', $stmt);
	if(@ads) {
		my $total = ($init->sql()->query('select', $count_stmt))[0]->{total};
		my $ng_pages = {};
		page_selections($start, $size, $total, $ng_pages);
		my $response = {
			ads => \@ads,
			pages => $ng_pages
		};
		$page_data->{json} = j_son($response);
		$$result = 1;
	}
}

sub create_admin_user_data {
	my ($init, $page_data, $result) = @_;
	my $start = $init->cgi()->param('start') || 0;
	my $size = $init->config('page_size');
	my $stmt = qq|select email,last_name,first_name,create_time,edit_time,signin_count from user order by create_time,edit_time desc limit $start,$size|;
	my $count_stmt = qq|select count(id) as 'total'	from user|;
	my @users = $init->sql()->query('select', $stmt);
	if(@users) {
		my $total = ($init->sql()->query('select', $count_stmt))[0]->{total};
		my $ng_pages = {};
		page_selections($start, $size, $total, $ng_pages);
		my $response = {
			users => \@users,
			pages => $ng_pages
		};
		$page_data->{json} = j_son($response);
		$$result = 1;
	}	
}

sub create_admin_category {
	my ($init, $page_data) = @_;
	my @cat = ();
	foreach($init->sql()->query('select', 'select * from category order by name')) {
		push(@cat, { id => $_->{id}, name => $_->{name}, name_cn => $_->{name_cn} });
	}
	my $response = {
		categories => \@cat
	};
	$page_data->{json} = j_son($response);
}

sub create_admin_subcategory {
	my ($init, $page_data) = @_;
	foreach($init->sql()->query('select', 'select * from category order by name')) {
		push(@{$page_data->{categories}}, { id => $_->{id}, name => $_->{name}, name_cn => $_->{name_cn} });
	}
	my $items = {};
	foreach($init->sql()->query('select', qq|select * from item order by name|)) {
		push(@{$items->{$_->{category_id}}}, { id => $_->{id}, name => $_->{name}, name_cn => $_->{name_cn} });
	}
	$page_data->{items} = $items;
	my @cats = @{$page_data->{categories}};
	$page_data->{default_category_id} = $cats[0]->{id};
	my $hash = {};
	foreach my $c_id (keys %{$items}) {
		$hash->{category}->{$c_id} = [];
		foreach(@{$items->{$c_id}}) {
			$_->{name} =~ s/'/\\'/g;
			$_->{name_cn} =~ s/'/\\'/g;
			push(@{$hash->{category}->{$c_id}}, {i=>$_->{id},n=>$_->{name},n_cn=>$_->{name_cn}});
		}
	}
	$page_data->{category_list} = $hash;
	$page_data->{json} = j_son($page_data);
}

sub create_activate_account_data {
	my ($init, $page_data) = @_;
	my $status = 0;
	if(defined $init->querystring()) {
		my $a = $init->querystring()->{a} || undef;
		my $v = $init->querystring()->{v} || undef;
		if(defined $a && defined $v) {
			my @user = $init->sql()->query('select', 'user', { acc_code => $a });
			if(@user) {
				if($user[0]->{active}) {
					$status = 2;
				}elsif($user[0]->{verify_str} ne $v) {
					$status = 3;
				}else {
					$init->sql()->query('update', 'user', { id => $user[0]->{id} }, { verify_str => '', acc_code => '', active => 1 });
					$init->sql()->commit();
					if($init->sql()->error()) {
						$status = 4;
					}else {
						$status = 1;
					}
				}
			}else {
				$status = 3;
			}
		}
	}
	$page_data->{status} = $status;
}

sub create_search_advertise_data {
	my ($init, $page_data, $result) = @_;
	my $keyword		= trim($init->cgi()->param('ad_keyword'));
	my $category	= trim($init->cgi()->param('category'));
	my $item		= trim($init->cgi()->param('item'));
	my $province	= trim($init->cgi()->param('province')); 
	my $city		= trim($init->cgi()->param('city')); 
	my $start		= trim($init->cgi()->param('start')) || 0;
	my $size		= $init->config('page_size');
	my $criteria = '';
	my $clause	= {};
	my @clause	= ();
	my @bind	= ();
	my @terms = ();
	my $keywords = '';
	if($province ne '') {
		$clause->{'a.province_id'} = $province;
		push(@terms, { text => {en=>static_content('all_provinces')->{$province}->{'name_en'},cn=>static_content('all_provinces')->{$province}->{'name_cn'}}, key => 'province' });
	}
	if($city ne '') {
		$clause->{'a.city_id'} = $city;
		push(@terms, { text => {en=>static_content('all_cities')->{$city}->{'name_en'},cn=>static_content('all_cities')->{$city}->{'name_cn'}}, key => 'city' });
	}
	if($category ne '') {
		$clause->{'a.category_id'} = $category;
		push(@terms, { text => {en=>static_content('all_categories')->{$category}->{'name_en'},cn=>static_content('all_categories')->{$category}->{'name_cn'}}, key => 'category' });
	}
	if($item ne '') {
		$clause->{'a.item_id'} = $item;
		push(@terms, { text => {en=>static_content('all_items')->{$item}->{'name_en'},cn=>static_content('all_items')->{$item}->{'name_cn'}}, key => 'item' });
	}
	if($keyword ne '') {
		my $keyword_clause = no_accent($keyword);
		$keyword_clause =~ s/'/\\'/g;
		$keywords = qq|(a.s_name regexp '$keyword_clause' or a.s_description regexp '$keyword_clause')|;
		push(@terms, { text => {en=>$keyword,cn=>$keyword}, key => 'ad_keyword' });
	}
	foreach(keys %{$clause}) {
		push(@clause, "$_=?");
		push(@bind, $clause->{$_});
	}
	push(@clause, $keywords) if($keywords);
	$criteria = join(" and ", @clause);
	$criteria .= " and " if($criteria);	
	
	my $stmt = "
		select a.id as 'id',a.name as 'name',a.html as 'html',a.description as 'description',a.is_free,a.price,a.currency,p.ids as 'picture_ids',a.city_id as 'city_id',a.province_id as 'province_id',date(a.create_time) as 'create_date',a.viewed as 'viewed',a.contact_method as 'contact_method',a.contact_phone as 'contact_phone',a.contact_email as 'contact_email'
		from advertise a left outer join (
		select advertise_id,group_concat(concat(id,' ',is_main,' ',edit_time) separator ',') as 'ids' from picture group by advertise_id
		) p
		on a.id=p.advertise_id
		where $criteria	a.active=1
		order by a.create_time desc
		limit $start,$size
	";
	my $count_stmt = "
		select count(a.id) as 'total'
		from advertise a where
		$criteria a.active=1
	";

	$keyword =~ s/'/\\'/g;
	$page_data->{search_item} = {
		pr => $province,
		ct => $city,
		ca => $category,
		it => $item,
		kw => $keyword	
	};

	my @ads = ();
	my $sth = $init->sql()->handle()->prepare($stmt);
	my $total = ($init->sql()->query('select', $count_stmt, \@bind))[0]->{total};
	my $ng_pages = { s => 1};
	page_selections($start, $size, $total, $ng_pages);
	$sth->execute(@bind);
	while(my $ad = $sth->fetchrow_hashref()) {
		if($ad->{picture_ids} eq '') {
			$ad->{picture_id} = 0;
			$ad->{picture_ids} = [];
		}else {
			my $pictures = {};
			my $main_picture_id = undef;
			my @picture_info = split(/\,/, $ad->{picture_ids});
			foreach my $picture (@picture_info) {
				my ($id, $is_main, $edit_time) = split(/ /, $picture);
				$main_picture_id = $id if($is_main);
				$pictures->{$id} = $edit_time;
			}
			my @pictures = sort { $pictures->{$b} cmp $pictures->{$a} } keys %{$pictures};
			if(!defined $main_picture_id) {
				$main_picture_id = $pictures[0];
			}
			$ad->{picture_id} = $main_picture_id;
			$ad->{picture_ids} = \@pictures;
		}
		$ad->{province} = { en => static_content('all_provinces')->{$ad->{province_id}}->{'name_en'}, cn => static_content('all_provinces')->{$ad->{province_id}}->{'name_cn'}, };
		$ad->{city} = { en => static_content('all_cities')->{$ad->{city_id}}->{'name_en'}, cn => static_content('all_cities')->{$ad->{city_id}}->{'name_cn'} };
		$ad->{price_display} = { en => LANG_LABELS->{'currency_'.$ad->{currency}}->{en}.$ad->{price}, cn => LANG_LABELS->{'currency_'.$ad->{currency}}->{cn}.$ad->{price} };
		push(@ads, $ad);
	}
	if(@ads) {
		$$result = 1;
		$page_data->{json} = j_son({angular_ads => \@ads, angular_ad_pages => $ng_pages, search_terms => \@terms, item => $page_data->{search_item}});
	}
}

sub create_user_account_data {
	my ($init, $page_data) = @_;
	if(defined $init->user()) {
		$page_data->{user} = $init->user();	
	}
}

sub create_user_advertise_data {
	my ($init, $page_data) = @_;
	if(defined $init->user()) {
		create_advertise_data($init, $page_data, { user_id => $init->user()->get('id') });	
	}
}

sub create_visitor_ad_data {
	my ($init, $page_data) = @_;
	if(defined $init->cookie()->get('v_session_id')) {
		my $visitor_ad_id = undef;
		my $session = new Class::Session($init->sql(), $init->cookie()->get('v_session_id'));
		if(defined $session) {
			if($session->expires($init->sql())) {
				$session->delete();
				$init->cookie()->delete(('v_session_id'));
				$session = undef;
				$init->sql()->commit();
			}else {
				$visitor_ad_id = $session->get('v_ad_id');
			}
		}
		if(defined $visitor_ad_id) {
			$page_data->{user_id} = $session->get('v_user_id');
			$page_data->{advertise_id} = $visitor_ad_id;
			create_edit_ad_data($init, $page_data);
		}
	} 
}

sub create_edit_ad_data {
	my ($init, $page_data) = @_;
	if(defined $page_data->{user_id} && defined $page_data->{advertise_id}) {
		create_advertise_data($init, $page_data, { user_id => $page_data->{user_id}, advertise_id => $page_data->{advertise_id} });	
		if(${$page_data->{advertises}}[0]) {
			$page_data->{advertise} = ${$page_data->{advertises}}[0];
			$page_data->{advertise}->{images} = $page_data->{advertise}->{picture_ids}; # for ng-post.js
			$page_data->{angular_ad} = j_son($page_data->{advertise});
		}
	}
}

sub create_page_permission_data {
	my ($init, $page_data) = @_;
	my @files = ();
	my $permission = {};
	my $dh = undef;
	opendir($dh, '/home/laoye/sites/advertise/perlroot');
	@file = grep { /^[a-z0-9_]+\.pl$/i } readdir($dh);
	closedir $dh;
	push(@files, @file);
	foreach($init->sql()->query('select', 'site_authenticate', { site => 'advertise' })) {
		$permission->{$_->{page}} = $_;
	}
	@files = sort { $a->{page} cmp $b->{page} } map(exists($permission->{$_}) ? $permission->{$_} : { page => $_ }, @files);
	$page_data->{files} = \@files;
	my $response = {
		files => \@files
	};
	$page_data->{json} = j_son($response);
}

sub validate_acc_code {
	my ($init, $page_data) = @_;
	my $a = $init->cgi()->param('acc_code') || undef;
	my $l = 'en';
	if($a =~ /(:?cn|en)$/) {
		$l = $1;
		$a =~ s/$1$//;
	}
	if(defined $a) {
		my @user = $init->sql()->query('select', 'user', { acc_code => $a });
		if(@user) {
			$page_data->{ok} = j_son({ok=>1,lang=>$l});
		}
	}
}

sub create_visitor_hits_data {
	my ($init, $page_data) = @_;
	my $start = $init->cgi()->param('start') || 0;
	my $cnt_stmt = qq|select count(distinct ip) as 'total' from visitor_hits|;
	my $total = ($init->sql()->query('select', $cnt_stmt))[0]->{total};
	my $size  = $init->config('page_size');
	my $stmt = qq|select count(ip) as 'count',ip,max(create_time) as 'create_time',current_date as 'this_day' from visitor_hits group by ip order by create_time desc,count desc limit $start, $size|;
	my @hits  = $init->sql()->query('select', $stmt);
	my $ng_pages = {};
	page_selections($start, $size, $total, $ng_pages);
	my $response = {
		hits => \@hits,
		pages => $ng_pages
	};
	$page_data->{json} = j_son($response);
}

sub queue_ad_image {
	my ($init, $data) = @_;
	my @data = sort {$a <=> $b} keys %{$data};
	my @error = ();
	my $count = 0;
	my $queue = {};
	if(@data) {
		foreach(@data) {
			$count++;
			my $file = trim($init->cgi()->param($data->{$_}->{file}));
			my $file_info  = $init->cgi()->uploadInfo($file);
			my $file_type  = defined $file_info ? $file_info->{'Content-Type'} : "";
			if($file_type) {
				if($file_type =~ /image.*(peg)|(gif)|(png)/i) {
					push(@{$queue->{image}}, $_);
				}else {
					push(@{$queue->{error}}, "Picture #$_->{num} --- only these types are supported: jpg, gif and png");
				}
			}else {
				push(@{$queue->{error}}, "Picture #$_->{num} --- something is wrong with your picture file");
			}
		}
	}
	return $queue;
}

sub upload_ad_image {
	my ($init, $image_queue) = @_;
	# image_queue --- hash reference, key is the picture.id the value is the associated image number from the html page
	my $unique_id = unique_id();
	foreach my $num (keys %{$image_queue}) {
		my $picture_id = $image_queue->{$num};
		my $file_name = $unique_id.'_'.$num;
		my $path = $init->config('upload_dir').'/'.$file_name;
		my $small = $init->config('small_image').'/'.$picture_id.'.jpg';
		my $big = $init->config('big_image').'/'.$picture_id.'.jpg';
		my $large = $init->config('large_image').'/'.$picture_id.'.jpg';
		my $big_mask = $init->config('upload_dir').'/'.'big_mask.jpg';
		my $upload_handle = $init->cgi()->upload('ad_image_'.$num);
		open(UPLOADFILE, ">$path");
		binmode UPLOADFILE;
		while(my $stream = <$upload_handle>) {
			print (UPLOADFILE $stream);
		}
		close(UPLOADFILE);
		my $size = $init->config('small_image_width')."x".$init->config('small_image_height');
		`convert -auto-orient -resize $size $path $small`;
		$size = $init->config('big_image_width')."x".$init->config('big_image_height');
		`convert -auto-orient -resize $size $path $big`;
		`composite $big -gravity center $big_mask $big`;
		$size = $init->config('large_image_width')."x".$init->config('large_image_height');
		`convert -auto-orient -resize $size $path $large`;
		`rm -f $path`;
	}
}

sub unique_id {
	my $dud	= new Data::UUID;
	my $sha	= new Digest::SHA;
	my $uuid = $dud->create();
	$sha->add($uuid);
	return $sha->hexdigest;
}

sub no_accent {
	my $source = shift;
	return defined $source ? lc(unac_string('utf-8', $source)) : '';
}

sub html_name {
	my ($id, $name) = @_;
	$name = trim($name);
	$name =~ s/[\s[:punct:]]+/-/g;
	return "$name-$id.html";	
}

sub trim {
	my $source = shift;
	return "" if(!defined $source || $source =~ /^ +$/);
	$source =~ s/\s+$//;
	$source =~ s/^\s+//;
	return $source;
}

sub is_nothing {
	my $entry = shift();
	$entry =~ s/[\r\n]//g;
	$entry =~ s/\s//g;
	return $entry eq '' ? 1 : 0;
}

sub site_encryption {
	my ($key1, $key2, $key3) = @_;
	my $sha = new Digest::SHA;
	$sha->add($key1, $key2, $key3);
	return $sha->hexdigest;
}

sub url_encode {
        my $str = shift;
        $str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
        return $str;
}

sub url_decode {
        my $str = shift;
        $str =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
        return $str;
}

sub is_something {
	my $str = shift;
	return defined $str && length($str) ? 1 : 0;
}

sub fields_not_blank {
	my $inputs = shift();
	my @array = @{$inputs};
	foreach(@array) {
			return 0 if(isNothing($_));
	}
	return 1;
}

sub page_selections {
    my ($current_index, $page_size, $total, $pages) = @_;
    my $page_number = $total % $page_size ? int($total / $page_size) + 1 : $total / $page_size;
    $pages = {} unless defined $pages;
    $pages->{c} = $current_index;
    for($i = 0; $i < $page_number; $i++) {
        push(@{$pages->{p}}, { i => $i * $page_size, n => $i + 1 });
    }
}

sub monthChar {
	my $chars = {
		"01" => "Jan",
		"02" => "Feb",
		"03" => "Mar",
		"04" => "Apr",
		"05" => "May",
		"06" => "Jun",
		"07" => "Jul",
		"08" => "Aug",
		"09" => "Sept",
		"10" => "Oct",
		"11" => "Nov",
		"12" => "Dec"
	};
	return $chars->{shift()};
}

sub dayOfWeek {
	my $chars = {
		1 => "Mon.",
		2 => "Tue.",
		3 => "Wed.",
		4 => "Thu.",
		5 => "Fri.",
		6 => "Sat.",
		7 => "Sun."
	};
	return $chars->{shift()};
}

sub dateTimeData {
	my ($value, $text, $array, $titleHash, $selected) = @_;
	my @array = @{$array};
	my $data = [{ $value=>$titleHash->{$value}, $text=>$titleHash->{$text}, selected => (defined $selected && $titleHash->{$value} =~ /^$selected$/) ? "selected" : "" }];
	for(my $index = 0; $index < scalar(@array); $index++) {
		my $hashValue = length($array[$index]) < 2 ? "0".$array[$index] : $array[$index];
		push(@{$data}, { 
			$value   => $hashValue, 
			$text    => $hashValue, 
			selected => (defined $selected && $hashValue =~ /^$selected$/) ? "selected" : ""
		});
	}
	return $data;
}

sub pageSelections {
	my ($currentIndex, $pageSize, $total) = @_;
	my $pageNumber = $total % $pageSize ? int($total / $pageSize) + 1 : $total / $pageSize;
	my $selections = [];
	for($i = 0; $i < $pageNumber; $i++) {
		push(@{$selections}, { 
			page_index => $i * $pageSize, 
			selected => $currentIndex == ($i * $pageSize) ? "selected" : "", 
			page_text => $i + 1 });
	}
	return $selections;
}

sub selectionData {
	my ($array, $titleHash, $selected) = @_;
	my $data = defined $titleHash ? [{ value=>$titleHash->{value}, text=>$titleHash->{text}, selected => (defined $selected && $titleHash->{value} =~ /^$selected$/) ? "selected" : "" }] : [];
	foreach(@{$array}) {
		push(@{$data}, {
			value    => $_->{value},
			text     => $_->{text},
			selected => (defined $selected && $_->{value} =~ /^$selected$/) ? "selected" : ""
		});
	}
	return $data;	
}

sub validDollar {
	my $dollar = "(0|([1-9]\\d*))(\\.\\d{1,})?";
	my $amount = shift();
	if($$amount =~ /^$dollar$/) {
		formatDollar(\$amount);
		return 1;
	}else {
		return 0;
	}
}

sub formatDollar {
	my $dollar = shift();
	$$dollar = sprintf("%.2f", $$dollar);
}

sub valid_email {
	my $email = shift();
	return ($email =~ /^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/) ? 1 : 0;
}

sub valid_phone {
	my $phone = shift();
	return ($phone =~ /^\d{10,20}$/) ? 1 : 0;
}

sub js_clean {
	my $source = shift();
	$source =~ s/[\r\n\t]//g;
	$source =~ s/'/\\'/g;
	$source =~ s/"/\\"/g;
	return $source;
}

sub valid_token {
	my ($sql, $token) = @_;
	return 0 unless $token;
	my @token = $sql->query('select', 'server_token', { token => $token });
	return @token ? 1 : 0;
}

sub gen_token {
	my $sql = shift;
	my $unique_id = unique_id();
	$sql->execute_stmt("insert into server_token (token,create_time) values (?,now())", [$unique_id]);
	$sql->commit(1);
	return $unique_id;
}

sub html_paragraph {
	my $source = shift();
	$source =~ s/\n/<br\/>/g;
	return $source;
}

sub j_son {
	my $obj = shift;
	return JSON::XS->new->encode($obj);
}

sub j_son_js {
	my $msg = shift;
    my $ng_msg = {};
    my $ng_count = 0;
    foreach(@{$msg}) {
        $ng_msg->{++$ng_count} = $_;
    }
	return j_son($ng_msg);
}

return 1;
