###
Dynamic include pulls in a partial template, and will automatically refresh
your view if that source template changes. This is very useful when developing
as you can avoid hitting the reload on your browser so much.

Parameters:
    src:    angular expression evaluating an URL, the content of which is the
            template to include

Use it like this:

<div dynamic-include src="'template-url.html'"/>

or like this:

<dynamic-include src="'template-url.html'"/>

Notice that src is an angular expression, so if you want a constant string make
sure to put it in ''!

You will need to add the 'dynamic' module as a dependency to your application
module.

###

module = angular.module('dynamic', [])
    .directive('dynamicInclude', ['$http', '$compile', '$timeout', ($http, $compile, $timeout) ->
            restrict: 'ECA'
            terminal: true
            replace: true
            compile: (sourceElement, sourceAttributes) ->
                #returning a linking function
                (scope, element) ->
                    watchCounter = 0
                    fetchCounter = 0
                    childScope = null
                    content = null
                    load = (src, counter) ->
                        #here is the actual dynamic include
                        $http.get(src, {params: {__fetch__: fetchCounter++}}).success (response, status, headers) ->
                            if content isnt response
                                content = response
                                console.log "loading #{src}"
                                childScope.$destroy() if childScope
                                childScope = scope.$new()
                                response = angular.element(response)
                                element.replaceWith(response)
                                element = response
                                $compile(element)(childScope)
                            if watchCounter is counter
                                $timeout ( -> load src, counter), 1000

                    #reload on the source expression changing, this is in a
                    #sense double dynamic, like ng-include it will reload
                    #if you change the expression for the template path
                    scope.$watch sourceAttributes.src, (src) ->
                        content = null
                        load(src, ++watchCounter) if src



    ])


