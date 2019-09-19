(function(angular) {
	'use strict';
	angular.module('esales')
	.factory('otherService', function() {
		var screen_error = {};
		var box_scope;
		var fns = {};
		fns['set_scope'] = function(s) {
			box_scope = s;
		};
		fns['get_scope'] = function() {
			return box_scope;
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
		fns['submit'] = function(fn, s) {
			var f = document.forms[fn];
			if(f) {
				check_input_fields(f, s);	
			}
		};
		return fns;
	})
	.controller('forgetPasswordController', ['$scope', 'otherService', function($scope, otherService) {
		$scope.fgtPasswd = otherService;
		$scope.fgtPasswd.set_scope($scope.fgtPasswd);
	}])
	.controller('userAccountController', ['$scope', 'otherService', function($scope, otherService) {
		$scope.userAccount = otherService;
		$scope.userAccount.set_scope($scope.userAccount);
	}]);
})(window.angular);
