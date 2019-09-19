package Class::Handle;

use strict;
use warnings;
use Class::Initialize;
use Class::Toolkit;
use Class::Utility qw(get_token);

sub handler {
	my $r	= shift;
	my $uri	= $r->uri;

    if($uri =~ /\.(gif|js|css|xml|jpg|ico|xls|csv|svg|ttf|woff)$/) {
        return Apache2::Const::DECLINED;
	}elsif ($uri =~ /\.php$|\.dll$|\.pl$/) {
		return Apache2::Const::DECLINED;
	}	
	
	my $init = new Class::Initialize();
	my $toolkit = $init->toolkit($init->config('main_template'));
	$r->content_type("text/html");

	if($init->success()) {
		my $page	= $init->page(); 
		if($page =~ /^\w+$/) {
			$init->template('advertise') unless -s $init->config('tmp_dir').'/'.$init->template();
			print $toolkit->string(get_token($init));
			return Apache2::Const::OK;			
		}elsif($page =~ /^[a-z0-9_\-]+\.html$/i) {
			my $doc  = $init->config('doc_root').$init->path().$page;
			if(-s $doc) {
				$r->headers_out->set(Location => $init->config('web_root').$init->path().$page);
				return Apache2::Const::REDIRECT;
			}else {
				$init->template('advertise');
				print $toolkit->string(get_token($init));
				return Apache2::Const::OK;			
			}
		}else {
			$init->template('advertise');
			print $toolkit->string(get_token($init));
			return Apache2::Const::OK;			
		}
	}else {
		$init->template('advertise') unless -s $init->config('tmp_dir').'/'.$init->template();
		print $toolkit->string(get_token($init));
		return Apache2::Const::OK;
	}
}

1;
