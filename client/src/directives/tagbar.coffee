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
                            if attrs.tagsQuery
                                matches = $scope.$eval(attrs.tagsQuery) (term) ->
                                    term.toLowerCase().indexOf(query.term.toLowerCase()) >= 0
                            else
                                matches = []
                            matches.unshift query.term
                            query.callback
                                results: matches
                        iconUrl: (tagValue) ->
                            if attrs.itemIconFrom is 'gravatar'
                                hash = md5((tagValue or '').toLowerCase())
                                return "http://www.gravatar.com/avatar/#{hash}.jpg?d=mm&s=#{iconSize}"
                            null
                        statusIcon: $scope.$eval(attrs.statusIconFrom) or null
                        tagClickable: $scope.$eval(attrs.tagClickEvent)
                        tagUrl: $scope.$eval(attrs.tagUrl)
                    #just propagate tag values back to the model
                    input.on 'change', (event) ->
                        $scope.$apply ->
                            ngModel.$setViewValue input.tagbar('val')
                            #no need for a render here, this control is doing
                            #a more thorough job of updating its ui
                            $scope.$emit 'edit'
                    $scope.$watch attrs.ngModel, (model) ->
                        ngModel.$render()
                    , true
                    #rendering is really just setting the values
                    ngModel.$render = () ->
                        if not ngModel.$viewValue
                            ngModel.$setViewValue {}
                        input.tagbar 'val', ngModel.$viewValue
                    $scope.$watch 'readonly-if', (readonly) ->
                        if readonly
                            element.addClass 'readonly'
                            element.find('*').addClass 'readonly'
                            input.tagbar 'disable'
                        else
                            element.removeClass 'readonly'
                            element.find('*').removeClass 'readonly'
                            input.tagbar 'enable'
        ])
        #used to display just one tag by itself
        .directive('tag', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                iconSize = attrs.itemIconSize or 32
                element.addClass 'tag'
                ngModel.$render = ->
                    options =
                        tagUrl: $scope.$eval(attrs.tagUrl)
                        iconUrl: (tagValue) ->
                            if $scope.$eval(attrs.itemIconFrom) is 'gravatar'
                                hash = md5((tagValue or '').toLowerCase())
                                return "http://www.gravatar.com/avatar/#{hash}.jpg?d=mm&s=#{iconSize}"
                            null
                        iconOnly: attrs.iconOnly?
                    element.onetag(ngModel.$viewValue, options)
        ])
