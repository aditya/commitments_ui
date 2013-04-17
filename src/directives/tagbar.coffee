#Tagbar, used to input multiple tags to allow open ended user filtering.
define ['angular',
    'lodash',
    'tagbar',
    'cs!src/editable'], (angular, _) ->
    module = angular.module('editable')
        #used to display an editable tag selection box
        .directive('tags', ['$timeout', ($timeout) ->
            restrict: 'A'
            require: 'ngModel'
            compile: (templateElement, templateAttrs) ->
                templateElement.addClass 'tags'
                templateAttrs.icon = templateAttrs.icon or 'tags'
                iconSize = templateAttrs.itemIconSize or 32
                ($scope, element, attrs, ngModel) ->
                    input = angular.element('<span class="tag-display"/>')
                    element.css 'cursor', 'default'
                    element.append input
                    input.tagbar
                        icon: templateAttrs.icon
                        query: (query) ->
                            query.callback
                                results: [query.term, 'sample']
                        iconUrl: (tagValue) ->
                            if attrs.itemIconFrom is 'gravatar'
                                hash = md5((tagValue or '').toLowerCase())
                                return "http://www.gravatar.com/avatar/#{hash}.jpg?s=#{iconSize}"
                            null
                    #just propagate tag values back to the model
                    input.on 'change', (event) ->
                        console.log event
                        $scope.$apply ->
                            ngModel.$setViewValue(input.tagbar('val'))
                    #rendering is really just setting the values
                    ngModel.$render = () ->
                        if not ngModel.$viewValue
                            ngModel.$setViewValue {}
                        input.tagbar 'val', ngModel.$viewValue
        ])
        #used to display just one tag by itself
        .directive('tag', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                ngModel.$render = ->
                    element.onetag(ngModel.$viewValue)
        ])
