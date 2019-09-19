function site_initialize() {
	check_mobile();
	setTimeout(function() {// windows 10 Microsoft Edge forces me for the timeout hack
		eEngine.start();
	}, 0);
}

function check_mobile() {
	is_mobile = navigator.userAgent.match(/(:?android|webos|iphone|ipad|ipod|blackberry|windows phone)/i) ? true : false;
}

function sniff_lang() {
    var url = window.location.href;
	if(url.match(/(:?cn|en)$/)) {
        site_lang = RegExp.$1;
        set_cookie('lang', site_lang);
    }
}

function page_location(url) {
	window.location.href = url;
}

function check_input_fields(f, s, a) {
	/* 
		s --- angular controller scope object passed in from a controller when the form submit button is clicked 
		all methods in that controller can be called on this scope object
		all model modifications are automatically watched by angular and the corresponding views and related error messages are updated
	*/
	var f_cp;
	var ef = false; // error flag
	var accessed = {}, values = {};
	if(s) { s.clear_screen_errors(); }
	for(var i = 0; i < f.elements.length; i++) {
		var e = f.elements[i], n = e.name, t = e.type;
		if(e.disabled) { continue; }
		if(typeof accessed[n] != 'undefined' || t.match(/^button$/i)) { continue; }
		accessed[n] = 1;
		values[n] = get_e_value(f, e);
		f_cp = copy_form_element(f, n, t);
	}
	var error = validate_input_fields(f, values);
	for(var elem in values) {
		if(typeof f_cp[elem] != 'undefined') {
			f_cp[elem].value = values[elem];
		}
		if(error[elem]) {
			ef = true;
			if(s) { s.add_screen_error(elem, error[elem]); }
		}else {
			if(s) { s.clear_screen_error(elem); }
		}
	}
    if(!ef && f.name == 'reset_password') {
        if(f['new_password'].value != f['confirm_new_password'].value) {
			ef = true;
			if(s) { s.add_screen_error('new_password', 'w_pwd_no_match'); }
		}
    }
	if(ef || a) { return; }
	/* no error and angular $http service is required, starting access server, generate a unique token to let the server ignore duplicate submissions */
	eEngine.ajax('request.pl', {action:'gen_token'}, eEngine.token, {f:f_cp});
}

function get_e_value(f, e) {
    if(e.type.match(/^radio$/i)) {
        for(var i = 0; i < f[e.name].length; i++) {
            if(f[e.name][i].checked) {
                return f[e.name][i].value;
            }
        }
		return '';
    }else if(e.type.match(/^checkbox$/i)) {
        var v = [];
        for(var i = 0; i < f[e.name].length; i++) {
            if(f[e.name][i].checked) {
                v.push(f[e.name][i].value);
            }
        }
        return v.join(",");
    }else {
        return e.value;
    }
}

function copy_form(f) {
    var f_cp = document.forms[f.name + '_cp'];
    if(typeof f_cp == 'undefined') {
        f_cp = document.createElement('form');
        f_cp.enctype = 'multipart/form-data';
        f_cp.name = f.name + '_cp';
        f_cp.method = 'post';
        f_cp.target = 'ajax_imitator';
        f_cp.action = f.action;
		var e = document.createElement('input');
		e.type = 'hidden';
		e.name = 'p_f_name';
		e.value = f.name;
		f_cp.appendChild(e);
		eEngine.dom('form_copy_wrapper').appendChild(f_cp);
    }
	return f_cp;
}

function copy_form_element(f, n, t) {
    var f_cp = copy_form(f);
    var input;
    if(typeof f_cp[n] == 'undefined') {
        if(t.match(/^textarea$/i)) {
            input = document.createElement('textarea');
            input.style.display = 'none';
        }else {
            input = document.createElement('input');
			if(t.match(/^(file)|(password)$/i)) {
				input.type = t;
				input.style.display = 'none';
			}else {
				input.type = 'hidden';
			}
        }
        input.name = n;
        f_cp.appendChild(input);
	}
    return f_cp;
}

function validate_input_fields(f, data) {
	var error = {};
	for(var field in data) {
		if(field.match(/^(?:(contact_name|first_name|last_name))$/)) {
			var n = RegExp.$1;
			if(data[field] == '') {
				error[field] = 'r_' + n;
			}
		}else if(field.match(/^email$/)) {
			if(data[field] == '') {
				error[field] = 'r_email';
			}else if(!valid_email(data[field])) {
				error[field] = 'w_email';
			}
		}else if(field.match(/^friend_email$/)) {
			if(data[field] == '') {
				error[field] = 'r_friend_email';
			}else if(!valid_email(data[field])) {
				error[field] = 'w_friend_email';
			}
		}else if(field.match(/^contact_message$/)) {
			if(data[field] == '') {
				error[field] = 'r_contact_message';
			}
		}else if(field.match(/^ad_name$/)) {
			if(data[field] == '') {
				error[field] = 'r_ad_name';
			}
		}else if(field.match(/^is_free$/)) {
			if(data[field] == '') {
				error[field] = 'r_is_free';
			}
		}else if(field.match(/^currency$/)) {
			if(data[field] == '') {
				error[field] = 'r_currency';
			}
		}else if(field.match(/^contact_method$/)) {
			if(data[field] == '') {
				error[field] = 'r_contact_method';
			}
		}else if(field.match(/^contact_phone$/)) {
			if(!f[field].disabled) {
				if(data[field] == '') {
					error[field] = 'r_contact_phone';
				}else if(!valid_phone(data[field])) {
					error[field] = 'w_contact_phone';
				}
			}
		}else if(field.match(/^message$/)) {
			if(data[field] == '') {
				error[field] = 'r_message';
			}
		}else if(field.match(/^price$/)) {
			if(!f[field].disabled) {
				if(data[field] == '') {
					error[field] = 'r_price';
				}else if(!valid_money_amount(data[field])) {
					error[field] = 'w_price';
				}
			}
		}else if(field.match(/^((confirm_)?new_)?password$/)) {
			if(data[field] == '') {
				if(!f.name.match(/^change_user_profile$/)) {
					error[field] = 'r_' + field;
				}
			}else if(!(data[field].match(/[a-z]+/i) && data[field].match(/\d+/) && data[field].length >= 10 && !data[field].match(/\s/))) {
				error[field] = 'w_' + field;
			}
		}else if(field.match(/^new_category$/)) {
			if(data[field] == '') {
				error[field] = "specify the category text";
			}
		}else if(field.match(/^category$/)) {
			if(data[field] == '') {
				error[field] = 'r_category';
			}
		}else if(field.match(/^item$/)) {
			if(data[field] == '') {
				error[field] = 'r_item';
			}
		}else if(field.match(/^province$/)) {
			if(data[field] == '') {
				error[field] = 'r_province';
			}
		}else if(field.match(/^city$/)) {
			if(data[field] == '') {
				error[field] = 'r_city';
			}
		}else if(field.match(/^email_phone$/)) {
			if(data[field].match(/^\s*$/)) {
				error[field] = 'r_email_phone';
			}
		}else if(field.match(/^post_id$/)) {
			if(data[field].match(/^\s*$/)) {
				error[field] = 'r_post_id';
			}
		}
	}
	return error;
}

function browse_file(frm, num) {
	var f_cp = document.forms[frm.name + '_cp'];
	f_cp['ad_image_' + num].click();
}

function select_file(frm, obj, n, s, t) {
	var info = obj.files[0];
	var e = '';
	if(!info.type.match(/^image\//i)) {
		e = 'w_pit_file';
	}else if((info.size/1048576) > angular_vars['imb']) {
		e = 'w_max_pit_size';
	}
	if(e) {
		t(function() {
			s.set_image_error(n, e);
		}, 0);		
		return false;
	}
	var f_cp = document.forms[frm.name + '_cp'];
	t(function() {
		s.clear_image_error();
	}, 0);		
	return true;
}

function preview_image(obj, n, s, t) {
	var info = obj.files[0];
	if (window.File && window.FileReader) {
		var reader = new FileReader();
		reader.readAsDataURL(obj.files[0]);
		reader.onload = function (evt) {
			t(function() {
				s.select_image(n, evt.target.result);
			}, 0);		
		};
	}
}

function valid_email(eml) {
	return eml.match(/^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/);	
}

function valid_phone(ph) {
	return ph.match(/^\d{10,20}$/);
}

function valid_money_amount(amt) {
	return !isNaN(amt);
}

function adm_load_data_item(f, type, item) {
	var items = adm_page_vars[type.name][type.value];
	var item_options = f[item];
	item_options.options.length = 0;
	if(items) {
		var len = items.length;
		for(var i = 0; i < len; i++) {
			var id = items[i]['i'];
			var name = items[i]['n'] + '::' + items[i]['n_cn'];
			item_options.options[i] = new Option(name, id);
		}
	}
}

function load_to_change(f, fld, chg_fld, chg_fld_cn, ed_box) {
	var box = eEngine.dom(ed_box);
	box.style.display = 'inline';
	var flds = fld.options[fld.selectedIndex].text.split('::');
	f[chg_fld].value = flds[0];
	f[chg_fld_cn].value = flds[1];
}	

function set_cookie(n, c) {
	document.cookie = n + '=' + c + ';path=/'; 
}

function trim_string(str) {
	return $.trim(str);
}

/*
the following are called in the context of AngularJS
*/
function add_success_message(js) {
	eEngine.model('message').msg(JSON.parse(js));
} 

function add_error_message(js) {
	eEngine.model('message').err(JSON.parse(js));
} 

function post_success(jsm, id) {
	eEngine.model('post').success(JSON.parse(jsm), id);
} 
