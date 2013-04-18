#manual bootstrap, allows coffeescript asynch load
define ['angular',
    'jquery',
    'src/etc',
    'cs!/src/controllers',
    'cs!/src/directives/tagbar',
    'cs!/src/directives/check',
    'cs!/src/directives/markdown',
    ], (angular, jquery) ->
    jquery ->
        angular.bootstrap document, ['Root']
