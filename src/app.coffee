#manual bootstrap, allows coffeescript asynch load
define ['angular',
    'jquery',
    'cs!/src/controllers',
    'cs!/src/directives/tagbar'], (angular, jquery) ->
    jquery ->
        angular.bootstrap document, ['Root']
