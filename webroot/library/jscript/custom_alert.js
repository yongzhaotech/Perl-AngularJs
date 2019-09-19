/*
	customized alert and confirm boxes
	Considering the checkbox 'Prevent this page from creating additional dialogs'
	If the user selects the checkbox and clicks on 'OK' button, subsequent alert or confirmation popups will not be displayed
	useage:
	var my_alert = new CustomAlert();
	my_alert.show(['Hello', 'Kanetix', 'Online Quote']), the passed in parameter can be a single string
	my_alert.confirm('Do you want to continue?', 
		function() {
			function_call // <- executed when 'OK' button is clicked
		}, 
		function() {
			function_call // <- executed when 'CANCEL' button is clicked, nothing happens if this function call is not passed in
		}
	);

*/
function CustomAlert(){
	var doc							= document.getElementsByTagName('body')[0];
    var doc_fragment				= document.createDocumentFragment();
    var c_sheet						= document.createElement('div');
    c_sheet.id						= '_cover_sheet_';
    c_sheet.style.display 			= 'none';
    c_sheet.style.position 			= 'absolute';
    c_sheet.style.top 				= 0;
    c_sheet.style.left 				= 0;
    c_sheet.style.right 			= 0;
    c_sheet.style.backgroundColor	= '#cccccc';
	c_sheet.style.opacity			= '0.5';
    c_sheet.style.zIndex 			= 999996;
    doc_fragment.appendChild(c_sheet);
    var a_sheet 					= document.createElement('div');
    a_sheet.id 						= '_sheet_contents_';
    a_sheet.style.display 			= 'none';
    a_sheet.style.position 			= 'fixed';
    a_sheet.style.zIndex 			= 999997;
    a_sheet.style.border 			= '1px solid #716161';
    a_sheet.style.padding 			= '0px';
	a_sheet.style.minHeight			= '80px;'
    doc_fragment.appendChild(a_sheet);

	this.elements = {
		_document:doc,
		_confirm:false,
		_message:false,
		_cover_sheet:c_sheet,
		_alert_sheet:a_sheet,
		_buttons:{
			width:'80px',
			cursor:'pointer',
			color:'#3507fa',
			background_color:'#ffffff',
			focus_color:'#ccccff',
			border:'1px solid #3507fa'
		}
	};

	var elem = this.tab_disabler('_disable_tabbing_top');
	this.elements._document.insertBefore(elem, this.elements._document.childNodes[0]);
	this.elements._disable_tabbing_top = elem;

    this.elements._document.appendChild(doc_fragment);

	elem = this.tab_disabler('_disable_tabbing_bottom');
	this.elements._document.appendChild(elem);
	this.elements._disable_tabbing_bottom = elem;
}

CustomAlert.prototype.confirm = function(args, ok_funcs, cancel_funcs) {
	this.elements._confirm = true;
	this.elements._ok_funcs = ok_funcs;
	this.elements._cancel_funcs = cancel_funcs;
	this.show(args);
}

CustomAlert.prototype.wait = function(args, ok_funcs) {
	this.elements._ok_funcs = ok_funcs;
	this.show(args);
}

CustomAlert.prototype.message = function(args) {
	this.elements._message = true;
	this.show(args);
}

CustomAlert.prototype.show = function(args) {
	this.elements._alert_sheet.innerHTML = '';
	if(is_mobile) { this.elements._alert_sheet.style.backgroundColor = '#ffffff'; }
	var alert_object = this;
	this.resize_cover();
	this.elements._cover_sheet.style.display = '';
	this.elements._alert_sheet.style.width = '';
	this.elements._alert_sheet.style.display = 'block';
	if(!this.elements._alert_contents) {
		var div = document.createElement('div');
		div.id = '_alert_contents_';
		div.style.padding = '15px 30px';
		div.style.wordWrap = 'break-word';
		this.elements._alert_contents = div;
	}
	this.elements._alert_contents.innerHTML = typeof args == 'object' ? '<ul><li>' + args.join('</li><li>') + '</li></ul>' : args;
	this.elements._alert_sheet.appendChild(this.elements._alert_contents);
	var ok = this.elements._message ? this.tab_disabler('_disable_tabbing_btn') : document.createElement('input');
	if(this.elements._message) {
		this.elements._alert_contents.appendChild(ok);
		this.elements._message = false;
	}else {
		var div = document.createElement('div');
		div.style.textAlign = 'center';
		div.style.padding = '15px';
		ok.type = 'button';
		ok.name = 'c_a_ok';
		ok.value = lang_messages['r_ok_btn'][site_lang];
		ok.style.width = this.elements._buttons.width;
		ok.style.cursor = this.elements._buttons.cursor;
		ok.style.color = this.elements._buttons.color;
		ok.style.border = this.elements._buttons.border;
		ok.style.backgroundColor = this.elements._buttons.background_color;
		ok.title = 'Click to continue';
		ok.onclick = function() {
			alert_object.close();
			if(alert_object.elements._ok_funcs) {
				alert_object.elements._ok_funcs.apply();
			}	
			delete alert_object.elements._ok_funcs;
			delete alert_object.elements._cancel_funcs;
			return true;
		}
		ok.onmouseover = function() {
			this.style.backgroundColor = alert_object.elements._buttons.focus_color;
			return true;
		}
		ok.onmouseout = function() {
			this.style.backgroundColor = alert_object.elements._buttons.background_color;
			return;
		}
		div.appendChild(ok);
		if(this.elements._confirm) {
			var space = '\u00a0';
			div.appendChild(document.createTextNode(space));
			var cancel = document.createElement('input');
			cancel.type = 'button';
			cancel.name = 'c_a_cancel';
			cancel.value = lang_messages['r_cancel_btn'][site_lang];
			cancel.style.width = this.elements._buttons.width;
			cancel.style.cursor = this.elements._buttons.cursor;
			cancel.style.color = this.elements._buttons.color;
			cancel.style.border = this.elements._buttons.border;
			cancel.style.backgroundColor = this.elements._buttons.background_color;
			cancel.title = 'Click to cancel';
			cancel.onclick = function() {
				alert_object.close();
				if(alert_object.elements._cancel_funcs) {
					alert_object.elements._cancel_funcs.apply();
				}
				delete alert_object.elements._ok_funcs;
				delete alert_object.elements._cancel_funcs;
				return true;
			}
			div.appendChild(cancel);
			this.elements._confirm = false;
			cancel.onmouseover = function() {
				this.style.backgroundColor = alert_object.elements._buttons.focus_color;
				return true;
			}
			cancel.onmouseout = function() {
				this.style.backgroundColor = alert_object.elements._buttons.background_color;
				return;
			}
		}
		this.elements._alert_sheet.appendChild(div);
	}
	this.relocate();
	ok.focus();
	window.onresize = function() {
		alert_object.resize_cover();
		if(!is_mobile) {
			alert_object.relocate();
		}
		return true;
	}
	window.onscroll = function() {
		if(is_mobile) { return; }
		alert_object.relocate();
		return true;
	}
}

CustomAlert.prototype.relocate = function() {
	if(is_mobile) { return; }
	var screen_info = {
		screen_width: parseInt(this.screen_width()),
		screen_height: parseInt(this.screen_height())
	};
    var s_height = screen_info['screen_height'] - 0;
    var two_over_three = screen_info['screen_width'] * 3 / 5;
    var box_width = this.elements._alert_sheet.offsetWidth;
    if(!is_mobile && box_width > two_over_three) {
        box_width = two_over_three;
        this.elements._alert_sheet.style.width = box_width + 'px';
    }
    if(this.elements._alert_sheet.offsetHeight > s_height) {
        this.elements._alert_sheet.style.overflowY = 'scroll';
    }else {
        this.elements._alert_sheet.style.overflowY = 'hidden';
    }
    this.elements._alert_sheet.style.top = (screen_info['screen_height'] - this.elements._alert_sheet.offsetHeight) / 2 + 'px';
    this.elements._alert_sheet.style.left = (screen_info['screen_width'] - box_width) / 2 + 'px';
}

CustomAlert.prototype.resize_cover = function() {
	var B = document.body, H = document.documentElement;
	this.elements._cover_sheet.style.height = Math.max(B.scrollHeight, B.offsetHeight, H.clientHeight, H.scrollHeight, H.offsetHeight) + 'px';
	if(!is_mobile) {
		this.elements._cover_sheet.style.width = Math.max(B.scrollWidth, B.offsetWidth, H.clientWidth, H.scrollWidth, H.offsetWidth) + 'px';
	}
}

CustomAlert.prototype.close = function() {
//	this.elements._cover_sheet.style.height = '0';
//	this.elements._cover_sheet.style.width = '0';
	this.elements._cover_sheet.style.display = 'none';
	this.elements._alert_sheet.innerHTML = '';
	this.elements._alert_sheet.style.display = 'none';
	this.elements._alert_contents.innerHTML = '';
}

CustomAlert.prototype.screen_width = function() {
    return Math.min(window.innerWidth|0, document.documentElement.clientWidth|0);
}

CustomAlert.prototype.screen_height = function() {
    return Math.min(window.innerHeight|0, document.documentElement.clientHeight|0);
}

CustomAlert.prototype.tab_disabler = function(id) {
	var elem = document.createElement('input');
	elem.id = id;
	elem.style.width = 0;
	elem.style.height = 0;
	elem.style.margin = 0;
	elem.style.padding = 0;
	elem.style.border = 0;
	elem.onfocus = function() {
		this.blur();
		return true;
	};
	return elem;
}

CustomAlert.prototype.content_sheet = function() {
	return this.elements._alert_sheet;
}

CustomAlert.prototype.cover_sheet = function() {
	return this.elements._cover_sheet;
}

CustomAlert.prototype.alert_sheet_zindex = function() {
	return this.elements._alert_sheet.style.zIndex;
}

CustomAlert.prototype.set_sheet_zindex = function(i) {
	this.elements._cover_sheet.style.zIndex = i;
	this.elements._alert_sheet.style.zIndex = i + 1;
}
