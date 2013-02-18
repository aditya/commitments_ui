module = angular.module('editable', [])
    .directive('editableText', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.bind 'blur', () ->
                $scope.$apply () ->
                    ngModel.$setViewValue(element.html())
            element.bind 'keydown', (event) ->
                if event.which is 27 #escape
                    event.target.blur()
                    event.preventDefault()
            ngModel.$render = () ->
                element.html ngModel.$viewValue
            element.attr 'contentEditable', true
            element.addClass 'editableText'
    ])

