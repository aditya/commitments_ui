###

###
AUTOHIDE_DELAY = 3000
HIDE_ANIMATION_DELAY = 400
module = angular.module('readonly', [])
    .directive('gravatar', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.addClass 'gravatar'
            size = attrs.size or 50
            icon = angular.element("<img width=#{size} height=#{size}></img>")
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
                        delay:
                            show: 100
                            hide: 100
                element.bind 'shown', ->
                    $timeout (-> element.tooltip 'hide'), AUTOHIDE_DELAY
    ])
    .directive('postdate', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.addClass 'postdate'
            $scope.$on 'edited', (event, record) ->
                if not ngModel.$viewValue
                    ngModel.$setViewValue Date.now()
                    ngModel.$render()
            ngModel.$render = ->
                if ngModel.$viewValue
                    element.text moment(ngModel.$viewValue).fromNow()
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
                        element.hide(HIDE_ANIMATION_DELAY)
                    else
                        element.hide()
                counter++
    ])
