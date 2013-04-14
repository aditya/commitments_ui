define [
    'bootstrap',
    ], () ->
    AUTOHIDE_DELAY = 3000
    ANIMATION_SPEED = 100
    module = angular.module('readonly', [])
        .directive('gravatar', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'gravatar'
                size = attrs.size or 50
                icon = angular.element("<img></img>")
                element.append(icon)
                ngModel.$render = ->
                    if not ngModel.$viewValue
                        ngModel.$setViewValue($scope.$eval(attrs.default))
                    hash = md5((ngModel.$viewValue or '').toLowerCase())
                    icon.attr 'src', "http://www.gravatar.com/avatar/#{hash}.jpg?s=#{size}"
        ])
        .directive('tooltip', ['$timeout', ($timeout)  ->
            restrict: 'A'
            compile: (templateElement, templateAttrs) ->
                ($scope, element, attrs) ->
                    placement = attrs.tooltipPlacement or 'top'
                    $scope.$watch templateAttrs.tooltip, (tooltip) ->
                        element.tooltip 'destroy'
                        element.tooltip
                            title: tooltip
                            placement: placement
                            container: 'body'
                            delay:
                                show: 100
                                hide: 100
                    element.bind 'shown', ->
                        $timeout (-> element.tooltip 'hide'), AUTOHIDE_DELAY
        ])
        .directive('username', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'username'
                element.append "<span class='icon-user'/>"
                display = angular.element "<span/>"
                element.append display
                ngModel.$render = ->
                    if ngModel.$viewValue
                        display.text ngModel.$viewValue
        ])
        .directive('postdate', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'postdate'
                element.append "<span class='icon-time'/>"
                display = angular.element "<span/>"
                element.append display
                ngModel.$render = ->
                    if ngModel.$viewValue
                        display.text moment(ngModel.$viewValue).fromNow()
        ])
        .directive('tag', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                ngModel.$render = ->
                    element.empty().append(makeATag(ngModel.$viewValue), false)
        ])
        .directive('animatedHide', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                #counter is in here so an initial hide isn't animated, just hidden
                #so we'll only animate if it was visible on the first pass
                counter = 0
                $scope.$watch attrs.animatedHide, (hide) ->
                    if hide
                        if counter
                            element.hide(ANIMATION_SPEED)
                        else
                            element.hide()
                    else
                        element.show()
                    counter++
        ])
        .directive('animatedShow', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                #counter is in here so an initial hide isn't animated, just hidden
                #so we'll only animate if it was visible on the first pass
                counter = 0
                $scope.$watch attrs.animatedShow, (show) ->
                    if show
                        if counter
                            element.show(ANIMATION_SPEED)
                        else
                            element.show(0)
                    else
                        if counter
                            element.hide(ANIMATION_SPEED)
                        else
                            element.hide(0)
                    counter++
        ])
        .directive('animatedVisible', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $scope.$watch attrs.animatedVisible, (show) ->
                    if show
                        element.animate
                            opacity: 1
                        , ANIMATION_SPEED
                    else
                        element.animate
                            opacity: 0
                        , ANIMATION_SPEED
        ])
