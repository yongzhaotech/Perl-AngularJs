(function(angular) {
	'use strict';
	angular.module('esales').run(function($rootScope) {
		angular.element(document).on("click", function(e) {
			$rootScope.$broadcast("screenClicked", angular.element(e.target));
		});
	});
	angular.module('esales')
	.controller('esalesController', ['$rootScope', '$scope', '$location', '$timeout', '$cookies', '$routeParams', 'siteEngine', function($rootScope, $scope, $location, $timeout, $cookies, $routeParams, siteEngine) {
		eEngine.register('post', $scope);
		$scope.engine = siteEngine;
		$scope.engine.hits();
		$scope.angular_ad = {};
		$scope.ang_models = ['prov_id','city_id','cat_id','item_id','name','is_free','currency','price','description','address'];
		$scope.screen_error = {};
		$scope.inum = angular_vars['inum'];
		$scope.group = '';
		$scope.prov_list = page_vars['province'];
		$scope.cat_list = page_vars['category'];
		$scope.expand_prov = false;
		$scope.expand_city = false;
		$scope.expand_cat = false;
		$scope.expand_item = false;
		$scope.index = function(v, d) {
			var l = d.length;
			for(var i = 0; i < l; i++) {
				if(d[i]['i'] == v) { return i; }
			}
			return 0;
		};
		$scope.load_advertise = function() {
			$scope.prov_id = $scope.city_id = '';
			$scope.cat_id = $scope.item_id = '';
			$scope.prov = page_vars['province'][$scope.index($scope.prov_id, page_vars['province'])];
			$scope.cat = page_vars['category'][$scope.index($scope.cat_id, page_vars['category'])];
		};
		$scope.load_advertise();	
		if($routeParams.advertise_id || $routeParams.behavior) {
			var script = '', req = {};
			if($routeParams.advertise_id) {
				script = 'user.pl', req = {action:'fetch_user_ad',advertise_id:$routeParams.advertise_id};
			}else if($routeParams.behavior && $routeParams.behavior == 'edit') {
				script = 'request.pl', req = {action:'fetch_visitor_ad'};
			}
			$scope.engine.server_request(script, req).then(function(promise) {
				if(promise.data.angular_ad) {
					$scope.angular_ad = promise.data.angular_ad;
					$scope.load_advertise_db();
				}else {
					$scope.angular_ad = {};
					$scope.load_advertise();	
					$scope.engine.models['msg'].err(promise.data);
				}
			});				
		}
/* start of customized dropdown selection */
		$scope.collapse = {
			prov: function() { $scope.expand_prov = false; },
			city: function() { $scope.expand_city = false; },
			cat: function() { $scope.expand_cat = false; },
			item: function() { $scope.expand_item = false; }
		};
		$scope.collapse_all = function(m) {
			for(var d in $scope.collapse) {
				if(d != m) {
					$scope.collapse[d]();
				}
			}
		};
		$scope.display_group = function(p) {
			if(p.s[$scope.engine.gb_lang()] != '' && p.s[$scope.engine.gb_lang()] != $scope.group) {
				$scope.group = p.s[$scope.engine.gb_lang()];
				return true;
			}
			return false;
		};
		$scope.prov_selected = function(p) {
			return $scope.prov_id && $scope.prov_id == p.i ? true : false;
		};
		$scope.select_prov = function(p) {
			$scope.expand_prov = !$scope.expand_prov;
			if($scope.expand_prov) {$scope.collapse_all('prov');}
			if($scope.prov_id == p.i) { return; }
			$scope.prov_id = p.i;
			$scope.prov_obj = p;
			$scope.prov = p;
			$scope.city_id = '';
		};
		$scope.selected_prov = function() {
			return $scope.prov_id;
		};
		$scope.show_prov = function(p) {
			return $scope.expand_prov || (!p.i && !$scope.prov_id) || ($scope.prov_id && $scope.prov_id == p.i) ? true : false;
		};
		$scope.city_selected = function(c) {
			return $scope.city_id && $scope.city_id == c.i ? true : false;
		};
		$scope.select_city = function(c) {
			$scope.city_id = c.i;
			$scope.city_obj = c;
			$scope.expand_city = !$scope.expand_city;
			if($scope.expand_city) {$scope.collapse_all('city');}
		};
		$scope.selected_city = function() {
			return $scope.city_id;
		};
		$scope.show_city = function(c) {
			return $scope.expand_city || (!c.i && !$scope.city_id) || ($scope.city_id && $scope.city_id == c.i) ? true : false;
		};
		$scope.cat_selected = function(c) {
			return $scope.cat_id && $scope.cat_id == c.i ? true : false;
		};
		$scope.select_cat = function(c) {
			$scope.expand_cat = !$scope.expand_cat;
			if($scope.expand_cat) {$scope.collapse_all('cat');}
			if($scope.cat_id == c.i) { return; }
			$scope.cat_id = c.i;
			$scope.cat_obj = c;
			$scope.cat = c;
			$scope.item_id = '';
		};
		$scope.selected_cat = function() {
			return $scope.cat_id;
		};
		$scope.show_cat = function(c) {
			return $scope.expand_cat || (!c.i && !$scope.cat_id) || ($scope.cat_id && $scope.cat_id == c.i) ? true : false;
		};
		$scope.item_selected = function(i) {
			return $scope.item_id && $scope.item_id == i.i ? true : false;
		};
		$scope.select_item = function(i) {
			$scope.item_id = i.i;
			$scope.item_obj = i;
			$scope.expand_item = !$scope.expand_item;
			if($scope.expand_item) {$scope.collapse_all('item');}
		};
		$scope.selected_item = function() {
			return $scope.item_id;
		};
		$scope.show_item = function(i) {
			return $scope.expand_item || (!i.i && !$scope.item_id) || ($scope.item_id && $scope.item_id == i.i) ? true : false;
		};
		$rootScope.$on("screenClicked", function(inner, target) {
			if(!$(target).parents("div.dp_wrapper").length) {
				$scope.$apply(
					function() {
						$scope.collapse_all();
					}
				); 
			}
		});
		$scope.store = {};
		$scope._contact_methods = {};
		$scope._remove_ad_images = {};
		$scope.contact_methods = {email:'',contact_phone:''};
		$scope.images = [];
		$scope.ad_images = {};
		$scope.selected_images = {};
		$scope.image_error = '';
		$scope.image_error_num = '';
		$scope.load_advertise_db = function() {
			if($scope.angular_ad['id']) {
				$scope.name = $scope.angular_ad['name'];
				$scope.is_free = $scope.angular_ad['is_free'];
				$scope.currency = $scope.angular_ad['currency'];
				$scope.price = $scope.angular_ad['price'];
				$scope.description = $scope.angular_ad['description'];
				$scope.main_picture_id = $scope.angular_ad['main_picture_id'];
				$scope.contact_methods['contact_email'] = $scope.angular_ad['contact_email'];
				$scope.contact_methods['contact_phone'] = $scope.angular_ad['contact_phone'];
				$scope.address = $scope.angular_ad['address'];
				$scope.images = $scope.angular_ad['images'].sort(function(a, b){return a - b});
				var methods = $scope.angular_ad['contact_method'].split(',');
				var l = methods.length;
				for(var i = 0; i < l; i++) {
					$scope._contact_methods[methods[i]] = 1;
				}
				l = $scope.images.length;
				for(var i = 0; i < l; i++) {
					$scope.ad_images[$scope.images[i]] = 1;
				}
				$scope.prov_id = $scope.angular_ad['province_id'];
				$scope.city_id = $scope.angular_ad['city_id'];
				$scope.prov = page_vars['province'][$scope.index($scope.prov_id, page_vars['province'])];
				if($scope.prov_id) { $scope.prov_obj = $scope.prov; }
				$scope.cat_id = $scope.angular_ad['category_id'];
				$scope.item_id = $scope.angular_ad['item_id'];
				$scope.cat = page_vars['category'][$scope.index($scope.cat_id, page_vars['category'])];
				if($scope.cat_id) { $scope.cat_name = $scope.cat['n']; }
			}
		};
/*end of dropdown selection*/
		$scope.set_currency = function(c) {
			$scope.currency = c;
		};
		$scope.set_main_picture = function(n) {
			$scope.main_picture_id = n;
		};
		$scope.ad_is_free = function() {
			$scope.price = '';
			$scope.is_free = 1;
			$scope.set_currency('');
		};
		$scope.ad_not_free = function() {
			$scope.is_free = 0;
		};
		$scope.set_contact_method = function(c) {
			if($scope._contact_methods[c]) {
				delete $scope._contact_methods[c];
				$scope.contact_methods[c] = '';
			}else {
				$scope._contact_methods[c] = 1;
			}
		};
		$scope.is_contact_method = function(c) {
			return $scope._contact_methods[c] ? true : false;
		};
		$scope.contact_method = function() {
			var arr = Object.keys($scope._contact_methods);
			return arr.join(',');
		};
		$scope.select_image = function(n, s) {
			$scope.selected_images[n] = s;
		};
		$scope.image_selected = function(n) {
			return $scope.selected_images[n] ? true : false;
		}
		$scope.set_image_error = function(n, e) {
			$scope.image_error = e;
			$scope.image_error_num = n;
		};
		$scope.clear_image_error = function() {
			$scope.image_error = '';
			$scope.image_error_num = '';
		};
		$scope.remove_ad_image = function(n) {
			var arr = Object.keys($scope._remove_ad_images);
			return arr.join(',');
		};
		$scope.image_found = function(n) {
			return $scope.ad_images[n] ? true : false;
		};
		$scope.add_ad_image = function() {
			var len = $scope.images.length;
			var n = len == 0 ? 1 : $scope.images[len - 1] * 1 + 1;
			$scope.images.push(n);
			$scope.add_image_selector(n);
		};
		$scope.add_image_selector = function(n) {
			var e = document.createElement('input');
			e.name = 'ad_image_' + n;
			e.type = 'file';
			e.onchange = function() {
				if(select_file($scope.store['fn'], e, n, $scope, $timeout)) {
					preview_image(e, n, $scope, $timeout);
				}
				return true;
			};
			if(!$scope.store['cfn']) {
				$scope.store['cfn'] = copy_form($scope.store['fn']);
			}
			$scope.store['cfn'].appendChild(e);
			if(!$scope.store['fs']) {
				$scope.store['fs'] = {};
			}
			$scope.store['fs'][n] = e;
		};
		$scope.browse_ad_image = function(n) {
			$timeout(function() {
				browse_file($scope.store['fn'], n);
			}, 0);
		};
		$scope.rm_ad_image = function(n) {
			var idx = $scope.images.indexOf(n);
			if(idx >= 0) {
				$scope.images.splice(idx, 1);
				if($scope.selected_images[n]) {
					delete $scope.selected_images[n];
				}
				if($scope.image_error_num == n) {
					$scope.clear_image_error();
				}
			}
			if(!$scope.ad_images[n]) {
				$scope.store['cfn'].removeChild($scope.store['fs'][n]);
			}
			if($scope.main_picture_id == n) {
				$scope.set_main_picture('');
			}
			if($scope.ad_images[n]) {
				delete $scope.ad_images[n];
				$scope._remove_ad_images[n] = 1;
			}
		};
		$scope.ad_image_full = function() {
			return $scope.images.length >= $scope.inum ? true : false;
		};
		$scope.register_form = function(fn) {
			$scope.store['fn'] = document.forms[fn];
		};
		$scope.add_screen_error = function(n, e) {
			$scope.screen_error[n] = e;
		};
		$scope.clear_screen_error = function(n) {
			if($scope.screen_error[n]) { delete $scope.screen_error[n]; }
		};
		$scope.clear_screen_errors = function() {
			$scope.screen_error = {};
		};
		$scope.has_screen_error = function() {
			return Object.keys($scope.screen_error).length ? true : false;
		};
		$scope.submit = function() {
			check_input_fields($scope.store['fn'], $scope);
			if(!$scope.has_screen_error()) {
				$timeout(function() {
					$scope.engine.models.msg.msg({1:$scope.engine.gb_labels('r_process'),2:$scope.engine.gb_labels('r_no_close'),3:$scope.engine.gb_labels('r_take_time')});
				}, 0);
			}
		};
		$scope.v_confirm_del = function() {
			$scope.engine.models.msg.con([$scope.engine.gb_labels('r_sure_delete')],function(){
				$scope.engine.server_request('delete_visitor_ad.pl', {action:'delete_visitor_ad'}).then(function(promise) {
					if(promise.data.ok) {
						$location.url('/home');
					}else {
						$scope.engine.models.msg.err(promise.data);
					}
				});
			});
		};
		$scope.success = function(m, i) {
			$scope.init_models();
			$scope.engine.models.msg.con(
				m,
				undefined,
				function() {
					$location.url('/ad_detail/' + i);
				}
			);
		};
		$scope.init_models = function() {
			$timeout(function() {
				$scope.angular_ad = {};
				var l = $scope.ang_models.length;
				for(var i = 0; i < l; i++) {
					eval("$scope." + $scope.ang_models[i] + " = '';");		
				}
				$scope.contact_methods = {email:'',	contact_email:'',contact_phone:''};
				$scope._contact_methods = {};
				$scope.prov = page_vars['province'][0]; 
				$scope.cat = page_vars['category'][0]; 
				$scope.images = [];
				$scope.collapse_all();
				var f_cp = document.forms[$scope.store['fn'].name + '_cp'];
				if(f_cp) {
					eEngine.dom('form_copy_wrapper').removeChild(f_cp);
				}
			}, 0);
		};
	}]) 
	.directive('adLocation', function() {
		return {
			templateUrl: function(elem, attr) {
				return '/ads/ng-template/location-' + attr.type + '.html';
			}
		};
	})
	.directive('adCategory', function() {
		return {
			templateUrl: function(elem, attr) {
				return '/ads/ng-template/category-' + attr.type + '.html';
			}
		};
	})
	.directive('imageList', function() {
		return {
			templateUrl: '/ads/ng-template/image-list.html'
		};
	});
})(window.angular);
/* legend:
	fn:			form name - name of the form
	cfn:		name of the copied form
	fs:			file selector
	ad_images:	list of image ids the existing ad has
*/
