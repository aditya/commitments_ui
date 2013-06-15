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
                link = document.createElement 'link'
                link.rel = "stylesheet/less"
                link.type = "text/css"
                link.href = "root.less"
                less.sheets.push link
                less.watch()
            'hot loading css'
