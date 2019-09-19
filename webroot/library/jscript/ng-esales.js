(function(angular) {
	'use strict';
	angular.module('esales', ['ngRoute', 'ngSanitize', 'ngCookies']);
	angular.module('esales')
	.config(['$locationProvider', '$routeProvider',
    	function config($locationProvider, $routeProvider) {
			$locationProvider.hashPrefix('!');
			$routeProvider.
        	when('/', {
          		template: '<advertise-list></advertise-list>'
			}).
			when('/ad_detail/:advertise_id', {
          		template: '<advertise-detail></advertise-detail>'
			}).
			when('/post_ad', {
				controller: 'esalesController',
          		templateUrl: '/ads/ng-template/html/post-ad.html'
			}).
			when('/edit_ad/:advertise_id', {
				controller: 'esalesController',
          		templateUrl: '/ads/ng-template/html/edit-ad.html'
			}).
			when('/visitor_ad/:behavior', {
				controller: 'esalesController',
          		templateUrl: '/ads/ng-template/html/visitor-ad.html'
			}).
			when('/user_account', {
          		template: '<user-account></user-account>'
			}).
			when('/set_pwd/:acc_code', {
          		template: '<set-password></set-password>'
			}).
			when('/user_advertise', {
          		template: '<user-advertise></user-advertise>'
			}).
			when('/admin_users', {
          		template: '<admin-users></admin-users>'
			}).
			when('/admin_ads', {
          		template: '<admin-ads></admin-ads>'
			}).
			when('/admin_perm', {
          		template: '<admin-perms></admin-perms>'
			}).
			when('/save_category', {
          		template: '<save-category></save-category>'
			}).
			when('/save_subcategory', {
          		template: '<save-subcategory></save-subcategory>'
			}).
			when('/visitor_hits', {
          		template: '<visitor-hits></visitor-hits>'
			}).
			when('/doc_hierarchy', {
          		templateUrl: '/ads/ng-template/html/doc-hierarchy.html'
			}).
			when('/pinnacle-sports', {
          		template: '<pinnacle-sports></pinnacle-sports>'
			}).
			when('/pinnacle-leagues/:sportsId', {
          		template: '<pinnacle-leagues></pinnacle-leagues>'
			}).
			when('/pinnacle-matchups/:leagueId', {
          		template: '<pinnacle-matchups></pinnacle-matchups>'
			}).
			otherwise('/');
		}
	])
	.factory('siteEngine', ['$rootScope', '$cookies', '$window', '$document', '$location', '$http', '$httpParamSerializer', '$timeout', function($rootScope, $cookies, $window, $document, $location, $http, $httpParamSerializer, $timeout) {
        var js_lang_toggles = {en:'cn', cn:'en'};
        var js_labels = lang_messages;
		var lang_cookie = $cookies.get('lang');
        var js_lang = lang_cookie ? lang_cookie : 'en';
        var http_headers = function() {
			var session_id = $cookies.get('session_id');
			var v_session_id = $cookies.get('v_session_id');
			var cookie = 'lang=' + js_lang;
			if(session_id) {cookie += '; ' + 'session_id=' + session_id;}
			if(v_session_id) {cookie += '; ' + 'v_session_id=' + v_session_id;}
			cookie += '; path=/ads/';
			return {
				'Set-Cookie': cookie,
				'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
			};
		};
        var http_get_headers = function() {
			return {
				'X-API-Key': 'EeycUJkxAvFrXVFjxUfRRvMHnXPniq8f'
			};
		};
		$document[0].title = js_labels['c_site_title'][js_lang];
		$rootScope.screen_scrollable = function() { return $(document).height() > $(window).height() ? true : false; };
		var server_get_request = function(u, d) {
			var config = {
				url: u,
				data: $httpParamSerializer(d),
				method: 'GET',
				headers: http_get_headers()
			};
			return $http(config);
		};
		var server_request = function(u, d) {
			var config = {
				url: '/adb/' + u,
				data: $httpParamSerializer(d),
				method: 'POST',
				headers: http_headers()
			};
			return $http(config);
		};
		var is_loading = false;
		var menu_clker_active = false;
		var models = {};
		var search_terms = [];
		var search_seq = {province:1,city:2,category:3,item:4,ad_keyword:5};
        var search_set = {
            criteria:{province:'',city:'',category:'',item:'',ad_keyword:'',start:''},
            result:{}
        };
		var clear_search = function() {
			search_set.result = {};
			angular.forEach(search_set.criteria, function(v, k) {
				search_set.criteria[k] = '';
			});
			angular.forEach(['prov_id','city_id','cat_id','item_id'], function(v, i) {
				models['box'][v] = '';
			});
		};
		var search_advertise = function() {
			var data = {};
            angular.forEach(search_set.criteria, function(v, k) {
					data[k] = v;
            });
			server_request('search_advertise.pl', data).then(function(promise) {
				if(promise.data.angular_ads) {
					search_set.result = promise.data;
					models['box'].boxes.detach('search'); // tell 'actionBoxController' to ask 'actionBoxes' service to detach the search box
					$location.path('/home');
				}else {
					models['msg'].err(promise.data);
				}
			});
		};
		var fns = {};
		fns['loading_data'] = function(b) { is_loading = b; };
		fns['is_loading_data'] = function() { return is_loading; };
		fns['menu_clker_active'] = menu_clker_active;
		fns['cookie'] = function(n) { var k = $cookies.get(n); return k ? k : ''; };
		fns['models'] = models; // components recorded into this object can be retrieved directly by other components, this works as a bridge among components into which this service is injected
		fns['register_model'] = function(n, m) { // record a component scope into 'models' object so it can be retrieved/accessed by other components
			models[n] = m;
		};
		fns['model'] = function(n) { // call this method from other components to retrieve/access a component scope by passing in its name
			return models[n];
		};
		fns['search_terms'] = search_terms;
		fns['search_seq'] = search_seq;
        fns['search_set'] = search_set;
		fns['clear_search'] = clear_search;
        fns['search_term'] = function(t) {
			var swap = {province:'prov_id',city:'city_id',category:'cat_id',item:'item_id'};
			angular.forEach(search_seq, function(v, k) {
				if(v > search_seq[t.key]) {
					search_set.criteria[k] = '';
					if(swap[k]) {
						models['box'][swap[k]] = '';
						if(k == 'category') { models['box'].cat.c = []; }
					}
					angular.forEach(search_terms, function(e, i) {
						if(e['key'] == t.key) {
							search_terms = search_terms.slice(0, i + 1); // clear sub search term from the search term list. e.g. a - b - c - d - e, when c is clicked, d and e are removed
						}
					});
				}
			});
			search_set.criteria.start = '';
			search_advertise();
		};
		fns['search_advertise'] = search_advertise;
		fns['user_signed_in'] = function() {
			return $cookies.get('session_id') ? true : false; // back end would validate the real signed in status
		};
		fns['set_language'] = function() {
			js_lang = js_lang_toggles[js_lang];
			$cookies.put('lang', js_lang);
			$window.site_lang = js_lang;
			$document[0].title = js_labels['c_site_title'][js_lang];
		};
		fns['gb_labels'] = function(l) {
			return js_labels[l][js_lang];
		};
		fns['gb_lang'] = function() {
			return js_lang;
		};
		fns['by_mail'] = function(a) {
			return a && a.contact_method && a.contact_method.match(/\b(contact_)?email\b/) ? true : false;
		};
		fns['by_phone'] = function(a) {
    		return a && a.contact_method && a.contact_method.match(/\bcontact_phone\b/) ? true : false;
        };
		fns['server_request'] = server_request;
		fns['server_get_request'] = server_get_request;
		fns['hits'] = function(p) {
			server_request('request.pl', {action:'hits',uri:p ? p : $location.url()}).then(function(promise) {});
		};
		return fns;
	}])
})(window.angular);
