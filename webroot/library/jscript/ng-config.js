(function(angular) {
	'use strict';
	angular.module('esales')
	.config(['$locationProvider', '$routeProvider',
    	function config($locationProvider, $routeProvider) {
			$locationProvider.hashPrefix('!');
			$routeProvider.
        	when('/', {
          		template: '<advertise-list></advertise-list>'
			}).
			when('/ads/:aid', {
          		template: '<advertise-detail></advertise-detail>'
			}).
			when('/post_ad', {
          		template: '<post-advertise></post-advertise>'
			}).
			when('/edit_ad/:aid', {
          		template: '<post-advertise></post-advertise>'
			}).
			when('/visitor_ad', {
          		template: '<post-advertise></post-advertise>'
			}).
			when('/user_account', {
          		template: '<user-account></user-account>'
			}).
			when('/user_advertise', {
          		template: '<user-advertise></user-advertise>'
			}).
			otherwise('/');
		}
	]);
})(window.angular);
