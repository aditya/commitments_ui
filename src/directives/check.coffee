#A very fancy checkbox using icons rather than input controls
define ['angular',
    'lodash',
    'tagbar',
    'cs!src/editable'], (angular, _) ->
    module = angular.module('editable')
        .directive('check', [ ->
            restrict: 'A'
            require: 'ngModel'
            compile: (templateElement, templateAttrs) ->
                templateElement.addClass 'check'
                ($scope, element, attrs, ngModel) ->
                    icon = angular.element("<span class='icon'/>")
                    element.append(icon)
                    element.on 'click', ->
                        $scope.$apply () ->
                            if ngModel.$viewValue
                                ngModel.$setViewValue ''
                            else
                                ngModel.$setViewValue Date.now()
                            ngModel.$render()
                    element.css 'cursor', 'pointer'
                    ngModel.$render = ->
                        icon.removeClass 'icon-check'
                        icon.addClass 'icon-check-empty'
                        if ngModel.$viewValue
                            icon.addClass 'icon-check'
                            icon.removeClass 'icon-check-empty'
        ])
