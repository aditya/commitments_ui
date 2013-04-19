#A very fancy checkbox using icons rather than input controls
define ['angular',
    'lodash',
    'tagbar',
    'cs!src/editable'], (angular, _) ->
    module = angular.module('editable')
        .directive('check', [ ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                    icon = angular.element("<span class='icon'/>")
                    element.addClass 'check'
                    element.append(icon)
                    element.css 'cursor', 'pointer'
                    element.on 'click', ->
                        if ngModel.$viewValue
                            value = 0
                        else
                            value = Date.now()
                        $scope.$apply () ->
                            console.log value, 'die fucker'
                            ngModel.$setViewValue value
                            ngModel.$render()
                            $scope.$emit 'edit', attrs.ngModel, ngModel
                    ngModel.$render = ->
                        icon.removeClass 'icon-check'
                        icon.addClass 'icon-check-empty'
                        if ngModel.$viewValue
                            icon.addClass 'icon-check'
                            icon.removeClass 'icon-check-empty'
        ])
