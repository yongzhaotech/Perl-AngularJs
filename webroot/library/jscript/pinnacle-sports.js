(angular => {
	'use strict';
	angular.module('esales')
	.factory('crescendoEngine', ['$http', '$httpParamSerializer', ($http, $httpParamSerializer) => {
        let http_get_headers = () => {
			return {
				'X-API-Key': 'EeycUJkxAvFrXVFjxUfRRvMHnXPniq8f'
			};
		};
		let server_get_request = (u, d) => {
			let config = {
				url: u,
				data: $httpParamSerializer(d),
				method: 'GET',
				headers: http_get_headers()
			};
			return $http(config); // promise, thenable
		};
		let fns = {};
		fns['server_get_request'] = server_get_request;
		return fns;
	}])
	.component('pinnacleSports', {
		templateUrl: '/ads/crescendo/ng-template/sports.html',
		controller: ['$location', '$timeout', 'crescendoEngine', function pinnacleSportsController($location, $timeout, crescendoEngine) {
			const _this = this;
			_this.engine = crescendoEngine;
			_this.selectSport = sport => {
				// route the url to the 'pinnacle-leagues' partial view
				$location.url('/pinnacle-leagues/' + sport.id);	
			};
			_this.engine.server_get_request('https://api.staging.lite.labs.pinnaclesports.com/0.7/sports', {}).then(promise => {
				// RESTful service responds with a promise resolved in JSON format
				_this.sports = promise.data; // inject into pinnacleSports component
				$timeout(() => {
					_this.loadDone = true;
				}, 1500);
			}).catch(/* hope there is no error */);
		}]
	})
	.component('pinnacleLeagues', {
		templateUrl: '/ads/crescendo/ng-template/leagues.html',
		controller: ['$routeParams', '$location', '$timeout', 'crescendoEngine', function pinnacleLeaguesController($routeParams, $location, $timeout, crescendoEngine) {
			const _this = this;
			const sportsId = $routeParams.sportsId;
			// use template literal to easily embed sportId in the request url
			const url = `https://api.staging.lite.labs.pinnaclesports.com/0.7/sports/${sportsId}/leagues`;
			_this.engine = crescendoEngine;
			_this.goToSport = () => {
				$location.url('/pinnacle-sports');			
			};
			_this.selectLeague = league => {
				// route the url to the 'pinnacle-matchups' partial view
				$location.url('/pinnacle-matchups/' + league.id);	
			};
			_this.engine.server_get_request(url, {}).then(promise => {
				// RESTful service responds with a promise resolved in JSON format
				_this.leagues = promise.data; // inject into pinnacleLeagues component
				_this.leagueTitle = _this.leagues[0].sport.name;
				$timeout(() => {
					_this.loadDone = true;
				}, 1500);
			}).catch(/* hope there is no error */);
		}]	
	})
	.component('pinnacleMatchups', {
		templateUrl: '/ads/crescendo/ng-template/matchups.html',
		controller: ['$routeParams', '$location', '$timeout', 'dateFilter', 'crescendoEngine', function pinnacleMatchupsController($routeParams, $location, $timeout, dateFilter, crescendoEngine) {
			const _this = this;
			const leagueId = $routeParams.leagueId;
			// use template literal to easily embed leagueId in the request url
			const url = `https://api.staging.lite.labs.pinnaclesports.com/0.7/leagues/${leagueId}/matchups`;
			_this.engine = crescendoEngine;
			_this.goToSport = () => {
				$location.url('/pinnacle-sports');			
			};
			_this.formatDate = d => {
				return dateFilter(new Date(d), 'MMM dd yyyy');
			};
			_this.goToLeague = id => {
				$location.url('/pinnacle-leagues/' + id);			
			};
			// for easy sorting of matchups by start time in the view
			let timeToNumber = t => {
				return t.replace(/:/, '') * 1;
			};
			_this.engine.server_get_request(url, {}).then(promise => {
				// RESTful service responds with a promise resolved in JSON format
				// to be grouped by date before injection into pinnacleMatchups component
				// to be sorted by time in ascending order in the template 
				let matchupsTmp = {}, matchups = [];
				angular.forEach(promise.data, (obj, index) => {
                    let dateTime = obj.startTime.match(/^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2})/);
                    let date = dateTime[1], time = dateTime[2];
                    if(!matchupsTmp[date]) { matchupsTmp[date] = []; }
                    let homeprice = 0, awayprice = 0, hometeam = 'unknown', awayteam = 'unknown';
                    if(obj.moneyline) { // exception already found in the returned json with null 'moneyline'
                        homeprice = obj.moneyline.filter(elem => elem.designation === 'home')[0]['price'];
                        awayprice = obj.moneyline.filter(elem => elem.designation === 'away')[0]['price'];
                    }
                    if(+homeprice > 0) { homeprice = '+' + homeprice; }
                    if(+awayprice > 0) { awayprice = '+' + awayprice; }
                    if(obj.participants) { // exception already found in the returned json with null 'participants'
                        hometeam = obj.participants.filter(elem => elem.alignment === 'home')[0]['name'];
                        awayteam = obj.participants.filter(elem => elem.alignment === 'away')[0]['name'];
                    }
                    matchupsTmp[date].push({
                        starttime: time,
                        timetonumber: timeToNumber(time),
                        hometeam: hometeam,
                        awayteam: awayteam,
                        homeprice: homeprice,
                        awayprice: awayprice
                    });
				});
				for(let date in matchupsTmp) {
					matchups.push({
						group: date,
						games: matchupsTmp[date]
					});	
				}
				_this.matchupCount = promise.data.length;
				_this.matchFound = _this.matchupCount ? true : false;
				_this.matchups = matchups.sort((a, b) => {
					let dateA = new Date(a.group);
					let dateB = new Date(b.group);
					return dateA-dateB;
				});
				_this.leagueTitle = promise.data[0].league.sport.name;
				_this.sportId = promise.data[0].league.sport.id;
				_this.matchUpName = promise.data[0].league.name;
				$timeout(() => {
					_this.loadDone = true;
				}, 1500);
			}).catch(/* hope there is no error */);
		}]	
	});
})(window.angular);
