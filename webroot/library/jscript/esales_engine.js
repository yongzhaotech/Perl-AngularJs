var eEngine = (function() {
	var _vars = {
		aj_err:{1:'There is an error, try again. Possible reasons:',2:'No internet connection',3:'Temporary system error',4:'Other unseen errors'},
		objs:{}
	};
	var token = function(j, o) {
		if(!o['f']['token']) {
			var e = document.createElement('input');
			e.type = 'hidden';
			e.name = 'token';
			o['f'].appendChild(e);
		}
		o['f']['token'].value = j.token;
		o['f'].submit();
	};
	var response = function(j, o) {
		o['r'] = j.r;
	};
	var ajax = function(u, d, f, o) {
		$.ajax({
			url: '/adb/' + u,
			type: 'POST',
			data: d,
			async: false,
			dataType: 'json'
		}).done(function(j) {
			if(f) {
				f(j, o);
			}
		}).fail(function() {
			err(_vars.aj_err);
		});
	};
	var jq = function(i) {
		if(!_vars.objs[i]) {
			var jq = $('#' + i);
			_vars.objs[i] = { j:jq.eq(0), d:jq.get()[0] };
		}
		return _vars.objs[i]['j'] || undefined;
	};
	var dom = function(i) {
		if(!_vars.objs[i]) {
			var jq = $('#' + i);
			_vars.objs[i] = { j:jq.eq(0), d:jq.get()[0] };
		}
		return _vars.objs[i]['d'] || undefined;
	};
	var start = function() {
		$('.ang_pre_hide').show();
		$(document).click();
	};
	var to = function(t) {
		$('html, body').animate({scrollTop: eEngine.jq(t).offset().top}, 1500);
	};
	var add_msg_model = function(m) { _vars.msg_model = m; };
	var add_pst_model = function(m) { _vars.pst_model = m; };
	var msg_model = function() { return _vars.msg_model; };
	var pst_model = function() { return _vars.pst_model; };
	return {
		add_msg_model: add_msg_model,
		add_pst_model: add_pst_model,
		msg_model: msg_model,
		pst_model: pst_model,
		token: token,
		response: response,	
		ajax: ajax,
		jq: jq,
		dom: dom,
		to: to,
		start: start
	};
})();
