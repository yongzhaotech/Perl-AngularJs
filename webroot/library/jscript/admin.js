function hit_details(visitor_ip) {
	var this_row = document.getElementById('ip_' + visitor_ip);
	var tb = get_parent(this_row);
	var this_index = this_row.rowIndex;
	if(iplistsviewed[visitor_ip] && document.getElementById('detail_' + visitor_ip)) {
		tb.removeChild(iplistsviewed[visitor_ip]);
		delete iplistsviewed[visitor_ip];
	}else {
		var v_ip = visitor_ip;
		var v_date = '';
		if(visitor_ip.match(/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})_(\d{4}-\d{2}-\d{2})$/)) {
			v_ip = RegExp.$1;
			v_date = RegExp.$2;
		}
		var new_row = tb.insertRow(this_index + 1);
		new_row.id = 'detail_' + visitor_ip;
		var td = document.createElement("td");
		td.colSpan = 3;
		td.style.padding = '3px 10px 3px 20px';
		new_row.appendChild(td);
		var data = {action:'admin_visitor_hits_list',session_id:frm.session_id.value};
		if(v_date) {
			data['visitor_ip'] = v_ip;
			data['visitor_date'] = v_date;
		}else {
			data['visitor_ip'] = visitor_ip;
		}
		var response = {};
		eEngine.ajax('admin.pl', data, eEngine.response, response);
		$(td).html(response['r']);
		iplistsviewed[visitor_ip] = new_row;
	}
}

function get_parent(obj) {
	if(obj) {
		return obj.parentElement ? obj.parentElement : obj.parentNode;
	}
}