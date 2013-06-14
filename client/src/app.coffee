#manual bootstrap, allows coffeescript asynch load
define ['angular',
    'jquery',
    './etc',
    'cs!./services',
    'cs!./controllers',
    'cs!./directives/tagbar',
    'cs!./directives/check',
    'cs!./directives/markdown',
    ], (angular, jquery) ->
    jquery ->
        angular.bootstrap document, ['Root']
        window.debugCSS = ->
            require ['lessc'], (less) ->
                $('style').remove()
                less.refreshStyles()
                less.refresh(true)
                #less.watch()
            'hot loading css'
