#manual bootstrap, allows coffeescript asynch load
define ['angular',
    'jquery',
    './etc',
    'cs!./services',
    'cs!./controllers',
    'cs!./directives/markdown',
    ], (angular, jquery) ->
    jquery ->
        #allow val to work with content editable. nice trick
        jquery.valHooks['li'] =
            get: (element) ->
                jquery(element).text()
            set: (element, value) ->
                jquery(element).text(value)
        #fire up out angular app
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
