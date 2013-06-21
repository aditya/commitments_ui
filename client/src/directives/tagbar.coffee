#Tagbar, used to input multiple tags to allow open ended user filtering.
define ['angular',
    'lodash',
    'tagbar',
    'cs!src/editable'], (angular, _) ->
    #yep -- make a gravatar
    gravatarUrl = (hash, iconSize) ->
        "http://www.gravatar.com/avatar/#{hash}.jpg?d=identicon&s=#{iconSize}"
    #building a single, stand along tag element
    makeATag = (options) ->
        #the main item, this stores the tag content
        tag = $ "<li class='tagbar-tag'/>"
        #display area, this is the main content
        display = $ "<span class='tagbar-tag-display'/>"
        #each tag may have an icon callback
        if options.iconUrl and typeof(options.iconUrl) is 'function'
            iconUrl = options.iconUrl options.data
            if iconUrl
                icon = $ "<image class='tagbar-tag-icon' src='#{iconUrl}'/>"
                tag.append icon
                display.addClass 'tagbar-tag-has-icon'
        #tags might be links, or just text
        if options.tagUrl and typeof(options.tagUrl) is 'function'
            display.append "<a href='#{options.tagUrl(options.data)}' class='tagbar-tag-text'>#{options.data}</a>"
        else if options.tagUrl
            display.append "<a href='#{options.tagUrl}' class='tagbar-tag-text'>#{options.data}</a>"
        else if options.data
            display.append "<span class='tagbar-tag-text'>#{options.data}</span>"
        #and a delete handle
        if options.allowDelete
            display.append "<span class='tagbar-tag-delete icon-remove-sign'/>"
        tag.append display
        #hover marking
        tag.hover (-> tag.find('*').addClass('hover')), (-> tag.find('*').removeClass('hover'))
        tag
    #
    module = angular.module('editable')
        #used to display an editable tag selection box
        .directive('tags', ['$timeout', ($timeout) ->
            restrict: 'A'
            require: 'ngModel'
            compile: (templateElement, templateAttrs) ->
                templateElement.addClass 'tags'
                iconSize = templateAttrs.itemIconSize or 32
                ($scope, element, attrs, ngModel) ->
                    input = angular.element('<span class="tag-display"/>')
                    element.css 'cursor', 'default'
                    element.append input
                    #just propagate tag values back to the model
                    input.on 'change', (event) ->
                        $scope.$apply ->
                            ngModel.$setViewValue input.tagbar('val')
                            #no need for a render here, this control is doing
                            #a more thorough job of updating its ui
                            $scope.$emit 'edit'
                    #initialization event will be fired by the tagbar
                    input.on 'initialized', (event) ->
                        #hook up a display icon if specified, this is inside
                        #the element, so if clicked will bubble events to the
                        #tagbar itself
                        if templateAttrs.icon
                            input.find('.tagbar-choices').prepend(
                                "<li class='tagbar-icon icon-#{templateAttrs.icon}'></li")
                    #set up the tagbar
                    input.tagbar
                        makeATag: makeATag
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
                                return gravatarUrl(hash, iconSize)
                            null
                        statusIcon: $scope.$eval(attrs.statusIconFrom) or null
                        tagClickable: $scope.$eval(attrs.tagClickEvent)
                        tagUrl: $scope.$eval(attrs.tagUrl)
                        allowDelete: true
                    $scope.$watch attrs.ngModel, (model) ->
                        ngModel.$render()
                    , true
                    #rendering with optional search word highlighting
                    hilightCount = 0
                    $scope.$watch attrs.searchHighlight, (value) ->
                        if hilightCount++ > 0
                            ngModel.$render()
                    #rendering is really just setting the values
                    ngModel.$render = () ->
                        if not ngModel.$viewValue
                            ngModel.$setViewValue {}
                        input.tagbar 'val', ngModel.$viewValue
                        if attrs.searchHighlight
                            search = $scope.$eval(attrs.searchHighlight)
                            if search
                                for word in search.split(' ')
                                    word = word.trim()
                                    if word
                                        re = new RegExp(word, 'gi')
                                        element.find('.tagbar-search-choice-text').each ->
                                            $(this).html $(this).text().replace(re, '<span class="highlight">$&</span>')
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
                                return gravatarUrl(hash, iconSize)
                            null
                        data: ngModel.$viewValue
                    element.children().remove()
                    element.append makeATag(options)
        ])
