#manual bootstrap, allows coffeescript asynch load
define ['angular',
    'jquery',
    'src/etc',
    'cs!/src/controllers',
    'cs!/src/directives/tagbar',
    'cs!/src/directives/check',
    'cs!/src/directives/markdown',
    'cs!/src/directives/toast',
    ], (angular, jquery) ->
    jquery ->
        angular.bootstrap document, ['Root']
