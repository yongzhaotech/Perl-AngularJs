(function(angular) {
	'use strict';
	angular.module('esales')
	.factory('userInformation', ['$location', '$timeout', '$cookies', 'siteEngine', function($location, $timeout, $cookies, siteEngine) {
		var engine = siteEngine;
		var loading = false;
		var errors = false;
		var error_message = '';
		var _acc_code = '';
		var _user = {};
		var _user_data = {};
		var clear_user_data = function(i) {
			angular.forEach(_user_data, function(v, k) {
				if(k != i && _user_data[k]) { delete _user_data[k]; }
			});
		};
		var fns = {};
		fns['loading'] = function() { return loading; }
		fns['errors'] = function(e) { if(e) { errors = true; } return errors; }
		fns['error_message'] = function() { return error_message; }
		fns['fetch_user_profile'] = function() {
			engine.server_request('user.pl', {action:'fetch_user_profile'}).then(function(promise) {
				_user.profile = promise.data.user;
			});
		};
		fns['fetch_user_ads'] = function() {
			engine.server_request('user.pl', {action:'fetch_user_ads'}).then(function(promise) {
				_user.ads = promise.data.ads;
			});
		};
		fns['fetch_adm_users'] = function(p) {
			if(!p) { loading = true; }
			if(p && _user_data.adm_users && _user_data.adm_users.pages.c == p.i) { return; }
			engine.server_request('admin.pl', {action:'fetch_adm_users',start:p ? p.i : 0}).then(function(promise) {
				if(promise.data.users) {
					clear_user_data('adm_users');
					errors = false;
					error_message = '';
					_user_data.adm_users = promise.data;
				}else {
					errors = true;
					error_message = promise.data.error;
				}
				loading = false;
			});
		};
		fns['fetch_adm_ads'] = function(p) {
			if(!p) { loading = true; }
			if(p && _user_data.adm_ads && _user_data.adm_ads.pages.c == p.i) { return; }
			engine.server_request('admin.pl', {action:'fetch_adm_ads',start:p ? p.i : 0}).then(function(promise) {
				if(promise.data.ads) {
					clear_user_data('adm_ads');
					errors = false;
					error_message = '';
					_user_data.adm_ads = promise.data;
				}else {
					errors = true;
					error_message = promise.data.error;
				}
				loading = false;
			});
		};
		fns['fetch_adm_files'] = function(p) {
			if(!p) { loading = true; }
			engine.server_request('admin.pl', {action:'fetch_adm_files'}).then(function(promise) {
				if(promise.data.files) {
					clear_user_data('adm_files');
					errors = false;
					error_message = '';
					_user_data.adm_files = promise.data;
				}else {
					errors = true;
					error_message = promise.data.error;
				}
				loading = false;
			});
		};
		fns['fetch_adm_categories'] = function(p) {
			if(!p) { loading = true; }
			engine.server_request('admin.pl', {action:'fetch_adm_categories'}).then(function(promise) {
				if(promise.data.categories) {
					clear_user_data('adm_categories');
					errors = false;
					error_message = '';
					_user_data.adm_categories = promise.data;
				}else {
					errors = true;
					error_message = promise.data.error;
				}
				loading = false;
			});
		};
		fns['fetch_adm_subcategories'] = function(p) {
			if(!p) { loading = true; }
			engine.server_request('admin.pl', {action:'fetch_adm_subcategories'}).then(function(promise) {
				if(promise.data.categories) {
					clear_user_data('adm_subcategories');
					errors = false;
					error_message = '';
					_user_data.adm_subcategories = promise.data;
					$timeout(function() {
						adm_page_vars = _user_data.adm_subcategories.category_list;
					}, 0);
				}else {
					errors = true;
					error_message = promise.data.error;
				}
				loading = false;
			});
		};
		fns['fetch_adm_visitor_hits'] = function(p) {
			if(!p) { loading = true; }
			if(p && _user_data.adm_visitor_hits && _user_data.adm_visitor_hits.pages.c == p.i) { return; }
			engine.server_request('admin.pl', {action:'fetch_adm_visitor_hits',start:p ? p.i : 0}).then(function(promise) {
				if(promise.data.hits) {
					clear_user_data('adm_visitor_hits');
					errors = false;
					error_message = '';
					_user_data.adm_visitor_hits = promise.data;
				}else {
					errors = true;
					error_message = promise.data.error;
				}
				loading = false;
			});
		};
		fns['acc_code'] = function() { return _acc_code; }
		fns['validate_acc_code'] = function(c) {
			loading = true;
			engine.server_request('request.pl', {action:'validate_acc_code',acc_code:c}).then(function(promise) {
 				if(promise.data.ok) {
					errors = false;
					_acc_code = c;
					$cookies.put('lang', promise.data.lang);
				}else {
					_acc_code = '';
					errors = true;
				}
				loading = false;
			});			
		};
		fns['gen_static_content'] = function() {
			engine.server_request('generate_static_content.pl', {action:'gen_static_content'}).then(function(promise) {
 				if(promise.data.ok) {
					engine.models['msg'].err(promise.data.ok);
				}else {
					engine.models['msg'].err(promise.data.error);
				}				
			});
		};
		fns['gen_static_htmls'] = function() {
			engine.server_request('generate_htmls.pl', {action:'gen_static_htmls'}).then(function(promise) {
 				if(promise.data.ok) {
					engine.models['msg'].err(promise.data.ok);
				}else {
					engine.models['msg'].err(promise.data.error);
				}				
			});
		};
		fns['sign_out'] = function() {
			engine.server_request('user.pl', {action:'sign_out'}).then(function(promise) {
				if(promise.data.ok) {
					_user = {};
					$location.url('/user_account');
				}else {
					engine.models['msg'].err(promise.data);
				}
			}, function(promise) {
				engine.models['msg'].err(promise.data);
			});
		};
		fns['remove'] = function(a) {
			var i = _user.ads.indexOf(a);
			if(i >= 0) {
				_user.ads.splice(i, 1);
			}
		};
		fns['user'] = function() {
			return _user.profile;
		};
		fns['ads'] = function() {
			return _user.ads;
		};
		fns['user_page'] = function(p) {
			$location.url('/' + p);
		};
		fns['odd_row'] = function(i) {
			return (i % 2 == 0) ? true : false;
		};
		fns['user_data'] = _user_data;
		return fns;
	}])
	.component('setPassword', {
		templateUrl: '/ads/ng-template/html/set-pwd.html',
		controller: ['$routeParams', 'userInformation', 'siteEngine', 'otherService', function setPwdController($routeParams, userInformation, siteEngine, otherService) {
			var _this = this;
			_this.account = userInformation;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.fgtPasswd = otherService;
			_this.fgtPasswd.set_scope(_this.fgtPasswd);
			if($routeParams.acc_code) {
				_this.account.validate_acc_code($routeParams.acc_code);
			}else {
				_this.account._acc_code = '';
				_this.account.errors(1);
			}
		}]	
	}) 
	.component('userAccount', {
		templateUrl: '/ads/ng-template/html/user-account.html',
		controller: ['$rootScope', '$timeout', '$cookies', 'actionBoxes', 'userInformation', 'siteEngine', 'otherService', function userAccountController($rootScope, $timeout, $cookies, actionBoxes, userInformation, siteEngine, otherService) {
			var _this = this;
			_this.account = userInformation;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.Account = otherService;
			_this.Account.set_scope(_this.Account);
			if(_this.engine.user_signed_in()) {
				_this.account.fetch_user_profile();
			}
		}]	
	}) 
	.component('userAdvertise', {
		templateUrl: '/ads/ng-template/html/user-advertise.html',
		controller: ['$rootScope', '$timeout', '$cookies', '$location', '$http', 'actionBoxes', 'userInformation', 'siteEngine', function userAccountController($rootScope, $timeout, $cookies, $location, $http, actionBoxes, userInformation, siteEngine) {
			var _this = this;
			_this.account = userInformation;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.expanded_ads = {};
			_this.account.fetch_user_profile();
			_this.account.fetch_user_ads();
			_this.edit_ad = function(a) {
				$location.url('/edit_ad/' + a.id);
			};
			_this.expand_user_ad = function(a) {
				if(_this.expanded_ads[a.id]) {
					delete _this.expanded_ads[a.id];
				}else {
					_this.expanded_ads[a.id] = 1;
				}
			};
			_this.user_ad_expanded = function(a) {
				return _this.expanded_ads[a.id] ? true : false;
			};
			_this.edit_ad = function(a) {
				$location.url('/edit_ad/' + a.id);
			};
			_this.delete_ad = function(a) {
				_this.engine.models['msg'].con([_this.engine.gb_labels('r_sure_delete')], function() {
					_this.engine.server_request('delete_advertise.pl', {aid: a.id}).then(function(promise) {
						if(promise.data.error) {
							_this.engine.models['msg'].err(promise.data.error);
						}else {
							_this.account.remove(a);
							$location.url('/user_advertise');
						}
					});
				});
			};
		}]	
	}) 
	.component('adminUsers', {
		templateUrl: '/ads/ng-template/adm/admin-users.html',
		controller: ['$rootScope', '$timeout', '$cookies', 'actionBoxes', 'userInformation', 'siteEngine', function adminController($rootScope, $timeout, $cookies, actionBoxes, userInformation, siteEngine) {
			var _this = this;
			_this.account = userInformation;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.account.fetch_user_profile();
			_this.account.fetch_adm_users();
			_this.users = function() { return _this.account.user_data.adm_users ? _this.account.user_data.adm_users.users : []; };
			_this.pages = function() { return  _this.account.user_data.adm_users ? _this.account.user_data.adm_users.pages.p : []; };
			_this.current_page = function() { return _this.account.user_data.adm_users ? _this.account.user_data.adm_users.pages.c : ''; };
		}]	
	}) 
	.component('adminAds', {
		templateUrl: '/ads/ng-template/adm/admin-ads.html',
		controller: ['$rootScope', '$timeout', '$cookies', 'actionBoxes', 'userInformation', 'siteEngine', function adminController($rootScope, $timeout, $cookies, actionBoxes, userInformation, siteEngine) {
			var _this = this;
			_this.account = userInformation;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.account.fetch_user_profile();
			_this.account.fetch_adm_ads();
			_this.ads = function() { return _this.account.user_data.adm_ads ? _this.account.user_data.adm_ads.ads : []; };
			_this.pages = function() { return  _this.account.user_data.adm_ads ? _this.account.user_data.adm_ads.pages.p : []; };
			_this.current_page = function() { return _this.account.user_data.adm_ads ? _this.account.user_data.adm_ads.pages.c : ''; };
			_this.set_status = function(a,b,c,d) {
				set_status(a,b,c,d);
			};
			_this.remove_ad = function(a,b,c) {
				_this.engine.models.msg.con([_this.engine.gb_labels('r_sure_delete')], function() {remove_ad(a,b,c);});
			};
		}]	
	}) 
	.component('adminPerms', {
		templateUrl: '/ads/ng-template/adm/admin-perm.html',
		controller: ['$rootScope', '$timeout', '$cookies', 'actionBoxes', 'userInformation', 'siteEngine', function adminController($rootScope, $timeout, $cookies, actionBoxes, userInformation, siteEngine) {
			var _this = this;
			_this.account = userInformation;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.account.fetch_user_profile();
			_this.account.fetch_adm_files();
			_this.files = function() { return _this.account.user_data.adm_files ? _this.account.user_data.adm_files.files : []; };
			_this.access_level = function(a,b,c) {
				access_level(a,b,c);
			};
			_this.check_ad = function(a,b,c) {
				check_ad(a,b,c);
			};
			_this.apply_permission_setting = function(a,b,c) {
				apply_permission_setting(a,b,c);
			};
		}]	
	}) 
	.component('saveCategory', {
		templateUrl: '/ads/ng-template/adm/save-category.html',
		controller: ['$rootScope', '$timeout', '$cookies', 'actionBoxes', 'userInformation', 'siteEngine', function adminController($rootScope, $timeout, $cookies, actionBoxes, userInformation, siteEngine) {
			var _this = this;
			_this.account = userInformation;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.account.fetch_user_profile();
			_this.account.fetch_adm_categories();
			_this.categories = function() { return _this.account.user_data.adm_categories ? _this.account.user_data.adm_categories.categories : []; };
		}]	
	}) 
	.component('saveSubcategory', {
		templateUrl: '/ads/ng-template/adm/save-subcategory.html',
		controller: ['$rootScope', '$timeout', '$cookies', 'actionBoxes', 'userInformation', 'siteEngine', function adminController($rootScope, $timeout, $cookies, actionBoxes, userInformation, siteEngine) {
			var _this = this;
			_this.account = userInformation;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.account.fetch_user_profile();
			_this.account.fetch_adm_subcategories();
			_this.categories = function() { return _this.account.user_data.adm_subcategories ? _this.account.user_data.adm_subcategories.categories : []; };
			_this.items = function() { return _this.account.user_data.adm_subcategories ? _this.account.user_data.adm_subcategories.items : {}; };
			_this.default_category_id = function() { return _this.account.user_data.adm_subcategories ? _this.account.user_data.adm_subcategories.default_category_id : ''; };
		}]	
	}) 
	.component('visitorHits', {
		templateUrl: '/ads/ng-template/adm/visitor-hits.html',
		controller: ['$rootScope', '$timeout', '$cookies', 'actionBoxes', 'userInformation', 'siteEngine', function adminController($rootScope, $timeout, $cookies, actionBoxes, userInformation, siteEngine) {
			var _this = this;
			_this.account = userInformation;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.account.fetch_user_profile();
			_this.account.fetch_adm_visitor_hits();
			_this.hits = function() { return _this.account.user_data.adm_visitor_hits ? _this.account.user_data.adm_visitor_hits.hits : []; };
			_this.pages = function() { return _this.account.user_data.adm_visitor_hits ? _this.account.user_data.adm_visitor_hits.pages.p : []; };
			_this.current_page = function() { return _this.account.user_data.adm_visitor_hits ? _this.account.user_data.adm_visitor_hits.pages.c : ''; };
			_this.hit_details = function(h) {
				hit_details(h.ip);
			};
		}]	
	}) 
	.directive('userTabs', function() {
		return {
			templateUrl: '/ads/ng-template/html/user-tabs.html'
		};
	});
})(window.angular);
