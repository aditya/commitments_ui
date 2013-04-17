#manual bootstrap, allows coffeescript asynch load
define ['angular',
    'jquery',
    'cs!/src/controllers',
    'cs!/src/directives/tagbar',
    'cs!/src/directives/markdown',
    ], (angular, jquery) ->
    jquery ->
        angular.bootstrap document, ['Root']
