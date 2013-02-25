###

###
module = angular.module('readonly', [])
    .directive('readonlyGravatar', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            size = attrs.size or 50
            icon = angular.element("<img width=#{size} height=#{size} class='gravatar'></img>")
            element.append(icon)
            ngModel.$render = ->
                hash = md5(ngModel.$viewValue)
                icon.attr 'src', "http://www.gravatar.com/avatar/#{hash}.jpg?s=#{size}"
    ])
