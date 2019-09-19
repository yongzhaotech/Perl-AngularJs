(function(angular) {
	'use strict';
	angular.module('esales').run(function($rootScope) {
		angular.element(document).on("click", function(e) {
			$rootScope.$broadcast("actionScreenClicked", angular.element(e.target));
		});
	});
	angular.module('esales')
	.factory('actionBoxes', ['$location', '$window', 'siteEngine', function($location, $window, siteEngine) {
		var screen_error = {};
		var engine = siteEngine;
		var box_scope;
		var page_boxes = {
			login:['email', 'password'],
			forget_password:['email'],
			register:['first_name', 'last_name', 'email', 'password'],
			contact_us:['email', 'subject', 'message'],
			ask_poster:['email', 'message', 'advertise_id'],
			email_friend:['email', 'friend_email', 'advertise_id'],
			find_visitor_ad:['email_phone', 'post_id'],
			search:[]
		};
		var http_service = {
			login:{c:'sign_in.pl',p:'user_advertise'},
			register:{c:'register.pl'},
			contact_us:{c:'request.pl'},
			ask_poster:{c:'request.pl'},
			email_friend:{c:'request.pl'},
			find_visitor_ad:{c:'request.pl',p:'visitor_ad/edit'},
			forget_password:{c:'forget_password.pl'}
		};
		var active_box = '';
		var active_ad = {id:'',name:''};
		var clear_box = function(b) {
			if(page_boxes[b]) {
				var f = document.forms[b + '_form'];
				if(f) {
					var len = page_boxes[b].length;
					for(var i = 0; i < len; i++) {
						if(typeof f[page_boxes[b][i]] != 'undefined') {
							f[page_boxes[b][i]].value = '';
						}
					}
					var f_cp = document.forms[b + '_form_cp'];
					if(f_cp) {
						eEngine.dom('form_copy_wrapper').removeChild(f_cp);
					}
				}
				screen_error = {};
			}	
			ad_action_box = null;
		};
		var fns = {};
		fns['clear_box'] = clear_box;
		fns['set_scope'] = function(s) {
			box_scope = s;
		};
		fns['get_scope'] = function() {
			return box_scope;
		};
		fns['attach_mailer'] = function(a, b) {
			if(active_box != b) {
				if(active_box) {
					clear_box(active_box);
				}
				active_box = b;
				active_ad['id'] = a['id'];
				active_ad['name'] = a['name'];
				ad_action_box = 1;
			}else {
				if(active_ad['id'] != a['id']) {
					clear_box(active_box);
					active_ad['id'] = a['id'];
					active_ad['name'] = a['name'];
					ad_action_box = 1;
				}
			}
		};
		fns['detach_mailer'] = function(b) {
			clear_box(b);
			active_ad = {id:'',name:''};
			active_box = '';			
		};
		fns['mailer_info'] = function() {
			return active_ad;
		};
		fns['index'] = function(v, d) {
			var l = d.length;
			for(var i = 0; i < l; i++) {
				if(d[i]['i'] == v) {
					return i;
				}
			}
			return 0;
		};
		fns['attach'] = function(b) {
			if(active_box != b) {
				if(active_box) {
					clear_box(active_box);
				}
				active_box = b;
				ad_action_box = 1;
			}
		}
		fns['detach'] = function(b) {
			clear_box(b);
			active_box = '';
		};
		fns['box_attached'] = function(b) {
			return active_box == b ? true : false;
		};
        fns['clear'] = function() {
			if(active_box) {
				clear_box(active_box);
            	active_box = '';
            	active_ad = {id:'',name:''};
			}
        };
		fns['errors'] = function() {
			return screen_error;
		};
		fns['add_screen_error'] = function(n, e) {
			screen_error[n] = e;
		};
		fns['clear_screen_error'] = function(n) {
			if(screen_error[n]) { delete screen_error[n]; }
		};
		fns['clear_screen_errors'] = function() {
			screen_error = {};
		};
		fns['has_screen_error'] = function() {
			return Object.keys(screen_error).length ? true : false;
		};
		fns['submit'] = function(s) {
			if(active_box) {
				var f = document.forms[active_box + '_form'];
				if(f) {
					// http_service - do not submit the form, instead use angular $http service
					check_input_fields(f, s, http_service[active_box]);
					if(http_service[active_box]) {
						engine.hits(active_box);
						var data = {action:active_box};
						angular.forEach(page_boxes[active_box], function(e, i) {
							data[e] = f[e].value;
						});
						if(!Object.keys(screen_error).length) {
							engine.server_request(http_service[active_box]['c'], data).then(function(promise) {
								if(promise.data.error) {
									engine.models['msg'].err(promise.data.error);
								}else {
									if(promise.data.message) {
										engine.models['msg'].msg(promise.data.message);
									}
									var page = http_service[active_box]['p'];
									clear_box(active_box);
									active_box = '';
									active_ad = {id:'',name:''};
									if(page) {
										$location.url('/' + page);									
									}
								}
							});
						}
					}
				}
			}
		};
		return fns;
	}])
	.controller('actionBoxController', ['$scope', '$rootScope', 'actionBoxes', '$cookies', '$window', '$document', '$location', 'siteEngine',  function($scope, $rootScope, actionBoxes, $cookies, $window, $document, $location, siteEngine) {
		eEngine.register('box', $scope);
		$scope.boxes = actionBoxes;
		$scope.engine = siteEngine;
		$scope.boxes.set_scope($scope.boxes);
		$scope.engine.register_model('box', $scope);
/* start of customized dropdown selection */
        $scope.group = '';
        $scope.prov_list = page_vars['province'];
        $scope.prov_id = $scope.engine.search_set.result.item ? $scope.engine.search_set.result.item.pr : '';
        $scope.city_id = $scope.engine.search_set.result.item ? $scope.engine.search_set.result.item.ct : '';
        $scope.prov = page_vars['province'][$scope.boxes.index($scope.prov_id, page_vars['province'])];
        $scope.cat_list = page_vars['category'];
        $scope.cat_id = $scope.engine.search_set.result.item ? $scope.engine.search_set.result.item.ca : '';
        $scope.item_id = $scope.engine.search_set.result.item ? $scope.engine.search_set.result.item.it : '';
        $scope.cat = page_vars['category'][$scope.boxes.index($scope.cat_id, page_vars['category'])];
        $scope.ad_keyword = $scope.engine.search_set.result.item ? $scope.engine.search_set.result.item.kw : '';
        $scope.expand_prov = false;
        $scope.expand_city = false;
        $scope.expand_cat = false;
        $scope.expand_item = false;
		$scope.home_page = function() {
			$scope.engine.clear_search();
			$location.url('/home');
		};
		$scope.go_to = function(p) {
			$location.url('/' + p);
		};
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
            $scope.prov = p;
            $scope.city_id = '';
			$scope.engine.search_set.criteria.province = p.i;
			$scope.engine.search_set.criteria.city = '';
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
            $scope.expand_city = !$scope.expand_city;
            if($scope.expand_city) {$scope.collapse_all('city');}
			$scope.engine.search_set.criteria.city = c.i;
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
            $scope.cat = c;
            $scope.item_id = '';
			$scope.engine.search_set.criteria.category = c.i;
			$scope.engine.search_set.criteria.item = '';
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
            $scope.expand_item = !$scope.expand_item;
            if($scope.expand_item) {$scope.collapse_all('item');}
			$scope.engine.search_set.criteria.item = i.i;
        };
        $scope.selected_item = function() {
            return $scope.item_id;
        };
        $scope.show_item = function(i) {
            return $scope.expand_item || (!i.i && !$scope.item_id) || ($scope.item_id && $scope.item_id == i.i) ? true : false;
        };
        $rootScope.$on("actionScreenClicked", function(inner, target) {
            if(!$(target).parents("div.dp_wrapper").length) {
				$scope.$apply(
					function() {
						$scope.collapse_all();
					}
				); 
            }
        });
/*end of dropdown selection*/
	}])
	.directive('adBox', function() {
		return {
			templateUrl: function(elem, attr) {
				return '/ads/ng-template/html/box-' + attr.type + '.html';
			}
		};
	})
	.directive('srhLocation', function() {
		return {
			templateUrl: function(elem, attr) {
				return '/ads/ng-template/location-' + attr.type + '.html';
			}
		};
	})
	.directive('srhCategory', function() {
		return {
			templateUrl: function(elem, attr) {
				return '/ads/ng-template/category-' + attr.type + '.html';
			}
		};
	});
})(window.angular);
