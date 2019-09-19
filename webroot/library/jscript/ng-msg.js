(function(angular) {
	'use strict';
	angular.module('esales').run(function($rootScope) {
		angular.element(document).on("click", function(e) {
			$rootScope.$broadcast("messageClicked", angular.element(e.target));
		});
	});
	angular.module('esales')
	.controller('messageController', ['$scope', '$rootScope', '$timeout', '$location', 'siteEngine', function($scope, $rootScope, $timeout, $location, siteEngine) {
		eEngine.register('message', $scope);
		$scope.engine = siteEngine;
		$scope.engine.register_model('msg', $scope);
        $scope.call_back = undefined;
        $scope.call_cancel = undefined;
		$scope.screen_error = {};
		$scope.success_message = {};
		$scope.images = [];
		$scope.list_images = [];
		$scope.cur_img = 0;
		$scope.err_flag = false;
		$scope.msg_flag = false;
		$scope.img_flag = false;
		$scope.menu_flag = false;
		$scope.fun_flag = false;
		$scope.site_msg_flag = function() { return $scope.err_flag || $scope.msg_flag };
		$scope.menus = angular_vars['menus'];
		$scope.add_screen_error = function(e) {
			$scope.clear_screen_errors();
			$timeout(function() {
				angular.forEach(e, function(v, k) {
					$scope.screen_error[k] = v;
				});
				$scope.err_flag = true;
			}, 0);
		};
		$scope.clear_screen_error = function(n) {
			if($scope.screen_error[n]) { delete $scope.screen_error[n]; }
		};
		$scope.clear_screen_errors = function() {
			$scope.screen_error = {};
			$scope.err_flag = false;
		};
		$scope.add_success_message = function(e) {
			$scope.clear_success_messages();
			$timeout(function() {
				angular.forEach(e, function(v, k) {
					$scope.success_message[k] = v;
				});
				$scope.msg_flag = true;
			}, 0);
		};
		$scope.clear_success_message = function(n) {
			if($scope.success_message[n]) { delete $scope.success_message[n]; }
		};
		$scope.clear_success_messages = function() {
			$scope.success_message = {};
			$scope.msg_flag = false;
		};
		$scope.img_index = function() {
			var l = $scope.images.length;
			for(var i = 0; i < l; i++) {
				if($scope.cur_img == $scope.images[i]['i']) {
					return i;
				}
			}
			return 0;
		};
		function load_images(imgs) {
			var images = [], cnt = imgs.length, func = function(){};
			angular.forEach(imgs, function(o, i) {
				var img = new Image();
				images[o.i] = img;
				img.src = '/ads/image/ad/large/' + o.i + '.jpg';
				img.onload = function() {
					cnt--;
					if(cnt === 0) { func(images); }
				};
				img.onerror = function() {
					cnt--;
					if(cnt === 0) { func(images); }
				};
			});
			return {
				finish: function(fn) {
					func = fn;
				}
			};
		}
		$scope.view_images = function(n) {
			$scope.images = $scope.list_images;
			if($scope.images.length) {
				load_images($scope.images).finish(function(imgs) {
					$timeout(function() {
						$scope.engine.loading_data(false);
						$scope.cur_img = n;
						$scope.img_flag = true;
					}, 1000);
				});
			}
			$scope.engine.loading_data(true);
		};
		$scope.has_next_image = function() {
			return $scope.img_index() < $scope.images.length - 1 ? true : false;
		};
		$scope.has_prev_image = function() {
			return $scope.img_index() > 0 ? true : false;
		};
		$scope.next_image = function() {
			$scope.cur_img = $scope.images[$scope.img_index() + 1]['i'];
		};
		$scope.prev_image = function() {
			$scope.cur_img = $scope.images[$scope.img_index() - 1]['i'];
		};
		$scope.clear_images = function() {
			$scope.images = [];
			$scope.list_images = [];
			$scope.cur_img = 0;
			$scope.img_flag = false;
		};
		$scope.load_menu = function() {
			$timeout(function() {	
				$scope.menu_flag = !$scope.menu_flag;	
				$scope.engine.menu_clker_active = $scope.menu_flag;
			}, 0);
		};
		$scope.clear_menus = function() {
			$scope.menu_flag = false;
			$scope.engine.menu_clker_active = false;
		};
		$scope.launch_menu = function(m) {
			$scope.clear_menus();
			if(m['b']) {
				$timeout(function() {
					$scope.engine.models.box.$apply(function () {
						$scope.engine.models.box.boxes.attach(m['a']);
					});
				}, 0);
			}else {
				$location.url('/' + m['a']);
			}
		};
        $scope.add_call_back = function(f, c) {
			$timeout(function() {
				$scope.clear_call_back();
				if(f) {
					$scope.call_back = f;
					$scope.fun_flag = true;
				}
				if(c) {
					$scope.call_cancel = c;
				}
			}, 0);
        };
        $scope.clear_call_back = function() {
            $scope.call_back = undefined;
            $scope.fun_flag = false;
            if($scope.call_cancel) {
                $scope.call_cancel();
                $scope.call_cancel = undefined;
            }
        };
        $scope.execute_func = function() {
            $timeout(function() {
                if($scope.call_back) {
                    $scope.call_back();
                }
                $scope.clear_func();
            }, 0);
        };
		$scope.clear_func = function() {
			$scope.clear_success_messages();
			$scope.clear_call_back();
		};
		$scope.con = function(m, f, c) {
			$scope.add_call_back(f, c);
			$scope.msg(m);
		};
		$scope.msg = function(m) {
			$scope.add_success_message(m);
		};
		$scope.err = function(e) {
			$scope.add_screen_error(e); 
		};
        $rootScope.$on("messageClicked", function(inner, target) {
            if(!$(target).parents("div#ang_message_wrapper").length) {
				$scope.$apply(
					function() {
						$scope.clear_screen_errors();
						$scope.clear_func();
						$scope.clear_images();
						if(!$(target).parents("div#menu_launcher").length) {
							$scope.clear_menus();
						}
					}
				); 
            }
        });
	}])
	.directive('screenMessage', function() {
		return {
			templateUrl: function(elem, attr) {
				return '/ads/ng-template/message-' + attr.type + '.html';
			}
		};
	});
})(window.angular);
