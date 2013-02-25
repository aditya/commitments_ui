###

###
AUTOHIDE_DELAY = 3000
module = angular.module('readonly', [])
    .directive('readonlyGravatar', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.addClass 'gravatar'
            size = attrs.size or 50
            icon = angular.element("<img width=#{size} height=#{size}></img>")
            element.append(icon)
            ngModel.$render = ->
                hash = md5(ngModel.$viewValue)
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
    .directive('readonlyPostdate', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.addClass 'postdate'
            ngModel.$render = ->
                element.text moment(ngModel.$viewValue).fromNow()
    ])
