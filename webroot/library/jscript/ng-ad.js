(function(angular) {
	'use strict';
	angular.module('esales')
	.component('advertiseDetail', {
		templateUrl: '/ads/ng-template/html/ad-detail.html',
		controller: ['$routeParams', '$timeout', 'actionBoxes', 'siteEngine', function adDetailController($routeParams, $timeout, actionBoxes, siteEngine) {
			var _this = this;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.engine.hits();
			_this.large_image = function(p) {
				$timeout(function() {
					_this.engine.models['msg'].list_images = _this.advertise.picture_ids;
					_this.engine.models['msg'].view_images(p.i);
				}, 0);
			};
			_this.engine.loading_data(true);
			_this.engine.server_request('advertise_detail.pl', {advertise_id: $routeParams.advertise_id}).then(function(promise) {
				if(promise.data.error) {
					_this.engine.models['msg'].err(promise.data.error);
				}else {
					_this.advertise = promise.data;
					_this.engine.search_terms = promise.data.search_terms // to be used to build search term list
					_this.engine.search_set.result = {
						item:{
							pr:promise.data.item.pr,
							ct:promise.data.item.ct,
							ca:promise.data.item.ca,
							it:promise.data.item.it,
							kw:promise.data.item.kw
						}
					};
					_this.engine.search_set.criteria.province = promise.data.item.pr;
					_this.engine.search_set.criteria.city = promise.data.item.ct;
					_this.engine.search_set.criteria.category = promise.data.item.ca;
					_this.engine.search_set.criteria.item = promise.data.item.it;
					_this.engine.search_set.criteria.ad_keyword = promise.data.item.kw;
					_this.engine.search_set.criteria.start = '';
					_this.engine.models.box.prov_id = promise.data.item.pr;
					_this.engine.models.box.prov = page_vars['province'][_this.boxes.index(promise.data.item.pr, page_vars['province'])];
					_this.engine.models.box.city_id = promise.data.item.ct;
					_this.engine.models.box.cat_id = promise.data.item.ca;
					_this.engine.models.box.cat = page_vars['category'][_this.boxes.index(promise.data.item.ca, page_vars['category'])];
					_this.engine.models.box.item_id = promise.data.item.it;
				}
				_this.engine.loading_data(false);
			});			
		}]
	})
	.component('advertiseList', {
		templateUrl: '/ads/ng-template/html/ad-list.html',
		controller: ['$rootScope', '$timeout', '$location', 'actionBoxes', 'siteEngine', function adsListController($rootScope, $timeout, $location, actionBoxes, siteEngine) {
			var _this = this;
			_this.boxes = actionBoxes;
			_this.engine = siteEngine;
			_this.$onInit = function() {				
				_this.columns = [1,2,3,4,5,6,7,8,9,10];
				_this.nav_col = 3;
				if(_this.engine.search_set.result.angular_ads) {
					_this.launch_search();
				}else {
					_this.launch_home();
				}
			};
			_this.flag_detail = function(ad) {
				_this.detail_flag = {};
				if(_this.open_flag && _this.open_flag == ad.id) {
					_this.open_flag = '';
				}else {
					_this.detail_flag[ad.id] = 1;
					_this.open_flag = ad.id;
				}
			};
			_this.html_desc = function(ad) {
				return ad.description ? ad.description.replace(/\n/g, '<br>') : '';
			};
			_this.show_detail = function(ad) {
				return _this.detail_flag[ad.id] ? true : false;
			};
			_this.launch_ad_detail = function(ad) {
				$location.url('/ad_detail/' + ad.id);
			};
			_this.launch_home = function(page) {
				_this.engine.hits();
				if(!page) { _this.engine.loading_data(true); }
				_this.engine.clear_search();
				if(page && _this.current_page == page.i) { return; }
				_this.engine.server_request('advertise.pl', {start:page ? page.i : 0}).then(function(promise) {
					if(promise.data.ads) {
						_this.ads = promise.data.ads.angular_ads;
						_this.pages = promise.data.ads.angular_ad_pages.p;
						_this.current_page = promise.data.ads.angular_ad_pages.c;
						_this.search_ad = false;
						_this.engine.search_terms = [];
						_this.engine.clear_search();
						_this.detail_flag = {};
						_this.open_flag = '';
						if(!page) {_this.nav_col = 3;}
						eEngine.to('t_c_spacer');						
					}
					_this.engine.loading_data(false);
				});
			};
			_this.launch_search = function() {
				_this.engine.hits();
				_this.ads = _this.engine.search_set.result.angular_ads;
				_this.pages = _this.engine.search_set.result.angular_ad_pages.p;
				_this.search_ad = _this.engine.search_set.result.angular_ad_pages.s ? true : false;
				_this.current_page = _this.engine.search_set.result.angular_ad_pages.c;
				_this.engine.search_terms = _this.engine.search_set.result.search_terms;			
				_this.detail_flag = {};
				_this.open_flag = '';
				eEngine.to('t_c_spacer');
			};
			_this.select_search_page = function(page) {
				if(_this.current_page != page.i) {
					_this.engine.search_set.criteria.start = page.i;
					_this.engine.search_advertise();
				}
			};
			_this.large_image = function(ad) {
				$timeout(function() {
					_this.engine.models['msg'].list_images = ad.picture_ids.map(function(p){return {i:p};});
					_this.engine.models['msg'].view_images(ad.main_picture_id || ad.picture_id, 1);
				}, 0);
			};
			var order_toggles = {price:'price * 1',create_date:'create_date','+':'-','-':'+'};
			_this.order = 'create_date';
			_this.sort = '+';
			_this.order_by = function() {
				return order_toggles[_this.sort] + order_toggles[_this.order];
			};
			_this.set_order = function(b) {
				_this.order = b;
				_this.sort = order_toggles[_this.sort];
			};
			_this.has_prev_col = function() {
				return _this.nav_col > _this.columns[0] ? true : false;
			};
			_this.has_next_col = function() {
				return _this.nav_col < _this.columns.slice(-1) * 1 ? true : false;
			};
			_this.prev_col = function() {
				_this.nav_col -= 1;
			};
			_this.next_col = function() {
				_this.nav_col += 1;
			};
		}]	
	}) 
	.directive('adDirective', function() {
		return {
			templateUrl: function(elem, attr) {
				return '/ads/ng-template/html/directive-' + attr.type + '.html';
			}
		};
	})
	.directive('searchTerms', function() {
		return {
			templateUrl: '/ads/ng-template/search-terms.html'
		};
	})
	.directive('adsList', function() {
		return {
			templateUrl: '/ads/ng-template/ads-list.html'
		};
	})
	.directive('pagesList', function() {
		return {
			templateUrl: '/ads/ng-template/pages-list.html'
		};
	});
})(window.angular);
