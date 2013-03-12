#manual bootstrap, allows coffeescript asynch load
define ['angular', 'jquery', 'cs!/src/controllers'], (angular, jquery) ->
    jquery ->
        angular.bootstrap document, ['Root']
