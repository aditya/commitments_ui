define ['md5',
    'markdown',
    'moment',
    'codemirror',
    'tagbar',
    'jqueryui',], (md5, markdown, moment) ->
    counter = 0;

    ANIMATION_SPEED = 200

    module = angular.module('editable', [])
        .directive('editableRecord', [() ->
            scope: true
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'editableRecord'
                $scope.$watch attrs.ngModel, (model) ->
                    #fields that are always required
                    if not model.id
                        model.id = md5("#{Date.now()}#{counter++}")
                    if not model.who
                        model.who = $scope.user.email
                    if model.$$required
                        if not model.when
                            model.when = Date.now()
                #look for field level edits, in which case this record was
                #updated
                $scope.$on 'edit', ->
                    $scope.$emit 'editableRecordUpdate', $scope.$eval(attrs.ngModel)
        ])
        .directive('editableListTools', [() ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $(element).find(attrs.editableListTools).hide()
                element.on 'click', 'li', (event) ->
                    $(element).find(attrs.editableListTools).hide()
                    $(event.currentTarget).find(attrs.editableListTools).show()
                element.on 'keydown', (event) ->
                    if event.which is 27 #escape
                        $(element).find(attrs.editableListTools).hide()
        ])
        .directive('requiredFor', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                #ensure the property is present and has a value
                $scope.$watch attrs.ngModel, (value) ->
                    target = $scope.$eval(attrs.requiredFor)
                    if value
                        target.$$required = true
                    else
                        target.$$required = false
        ])
        .directive('editableListReorder', [() ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                #using jQuery, so this is not all that impressive
                if attrs.handle
                    console.log element.sortable
                    element.sortable
                        cursor: 'move'
                else
                    element.sortable
                        cursor: 'move'
                element.css 'cursor', 'move'
                element.on 'sortupdate', ->
                    $scope.stackRank.renumber(
                        element.children('.editableRecord').map((_, x) -> $(x).data 'record'),
                        $scope.user.email,
                        $scope.$eval(attrs.editableListReorder))
        ])
        .directive('editable', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                #make sure there is always a list if we change models
                #with a counter so this does not fire on the initial update
                count = 0
                $scope.$watch attrs.ngModel, (value) ->
                    if count++
                        console.log value
                        $scope.$emit 'edit'
        ])
        .directive('editableList', ['$timeout', ($timeout) ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                #make sure there is a model
                if not ngModel.$modelValue
                    ngModel.$modelValue = []
                #ability to create a placeholder record
                newPlaceholder = ->
                    if not ngModel.$modelValue.$$placeholder
                        record = {}
                        if attrs.onPlaceholder
                            $scope.$eval("#{attrs.onPlaceholder}")(record)
                        ngModel.$modelValue.$$placeholder = record
                        ngModel.$modelValue.push record
                #make sure there is always a list if we change models
                $scope.$watch attrs.ngModel, ->
                    if not ngModel.$viewValue
                        ngModel.$setViewValue([])
                    #and the initial placeholder
                    if attrs.editableListBlankRecord?
                        newPlaceholder()
                #and record updates, deal with the delete logic that fires when
                #the required field is empty
                $scope.$on 'editableRecordUpdate', (event, record) ->
                    #this is a signal to delete the thing
                    if not record.$$required and record isnt ngModel.$modelValue.$$placeholder
                        list = ngModel.$modelValue
                        foundAt = list.indexOf(record)
                        if foundAt >= 0
                            list.splice(foundAt, 1)
                        if attrs.onDelete
                            $scope.$eval("#{attrs.onDelete}")(record)
                    #once you have the required field, you are no longer placeholder
                    #and are an actual new record
                    if record.$$required and record is ngModel.$modelValue.$$placeholder
                        if attrs.editableListBlankRecord?
                            ngModel.$modelValue.$$placeholder = null
                            newPlaceholder()
                        if attrs.onCreate
                            $scope.$eval("#{attrs.onCreate}")(record)
                    #and updates
                    if record.$$required and record isnt ngModel.$modelValue.$$placeholder
                        if attrs.onUpdate
                            $scope.$eval("#{attrs.onUpdate}")(record)
                    event.stopPropagation()
        ])
        .directive('markdown', ['$timeout', ($timeout) ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'markdown'
                element.addClass 'editable'
                attachTo = angular.element("<div></div>")
                attachTo.hide()
                display = angular.element("<div class='display'></div>")
                if attrs.multiline?
                    display.addClass 'multiline'
                else
                    display.addClass 'oneline'
                element.append display, attachTo
                codemirror = null
                #hook on to any way in the field
                element.on 'click dblclick focus', () ->
                    if element.hasClass 'readonly'
                        return
                    #only hook up the editor if there isn't one
                    if not codemirror
                        element.addClass 'editing'
                        codemirror = CodeMirror attachTo[0]
                        codemirror.setOption 'lineWrapping', true
                        attachTo.width('100%')
                        attachTo.height('auto')
                        if attrs.multiline?
                            #automatic expanding of size
                            $('.CodeMirror-scroll', attachTo)
                                .css('overflow-x', 'auto')
                                .css('overflow-y', 'hidden')
                            $('.CodeMirror', attachTo).css('height', 'auto')
                        else
                            $('.CodeMirror', attachTo).css('height', '100%')
                            #trap enter, preventing multiple lines being added
                            #yet still allow 'wrapped' single line to be
                            #visually multiple lines in the DOM
                            codemirror.setOption 'extraKeys',
                                Enter: (cm) ->
                                    #hard core trigger a blur
                                    $('.CodeMirror', attachTo).remove()
                                Down: (cm) ->
                                    #supress, not allowing line navigation
                                    null
                        codemirror.on 'blur', ->
                            value = codemirror.getValue().trimLeft().trimRight()
                            ngModel.$setViewValue(value)
                            ngModel.$render()
                            $scope.$digest()
                            $timeout ->
                                display.show 100
                                attachTo.hide 100, ->
                                    codemirror = null
                                    element.removeClass 'editing'
                                    $('.CodeMirror', attachTo).remove()
                        codemirror.setValue ngModel.$viewValue or '\n'
                        display.hide 100
                        attachTo.show 100, ->
                            codemirror.focus()
                            codemirror.setOption('mode', 'markdown')
                            codemirror.setOption('theme', 'neat')
                            codemirror.refresh()
                element.on 'keydown', (event) ->
                    if event.which is 27 #escape
                        event.target.blur()
                ngModel.$render = () ->
                    #markdown based display
                    if ngModel.$viewValue
                        display.removeClass('placeholder')
                        display.html(markdown.toHTML(ngModel.$viewValue))
                    else if attrs.placeholder
                        display.addClass('placeholder')
                        display.html($scope.$eval(attrs.placeholder))
        ])
        .directive('tags', ['$timeout', ($timeout) ->
            restrict: 'A'
            require: 'ngModel'
            compile: (templateElement, templateAttrs) ->
                templateElement.addClass 'tags'
                templateElement.addClass 'editable'
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
                    input.on 'blur change', (event) ->
                        if attrs.onChange
                            $scope.$eval(attrs.onChange)(input.tagbar('previous'), input.tagbar('val'))
                        $scope.$apply ->
                            ngModel.$setViewValue(input.tagbar('val'))
                    #rendering is really just setting the values
                    ngModel.$render = () ->
                        if not ngModel.$viewValue
                            ngModel.$setViewValue {}
                        input.tagbar 'val', ngModel.$viewValue
                    $scope.$watch attrs.ngModel,( (val) ->
                        ngModel.$render()
                    ), true
        ])
        .directive('action', ['$timeout', ($timeout) ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.css 'cursor', 'pointer'
        ])
        .directive('check', [ ->
            restrict: 'A'
            require: 'ngModel'
            compile: (templateElement, templateAttrs) ->
                templateElement.addClass 'check'
                templateElement.addClass 'editable'
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
        .directive('requiresObject', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                for objectName in attrs.requiresObject.split(',')
                    objectName = objectName.trim()
                    if not $scope.$eval(objectName)
                        $scope.$eval("#{objectName}={}")
        ])
        .directive('requiresInt', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                if not $scope.$eval(attrs.requiresInt)
                    $scope.$eval("#{attrs.requiresInt}=0")
        ])
        .directive('requiresArray', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                if not $scope.$eval(attrs.requiresArray)
                    $scope.$eval("#{attrs.requiresArray}=[]")
        ])
        .directive('activeIf', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $scope.$watch attrs.activeIf, (val) ->
                    if val
                        element.addClass 'active'
                    else
                        element.removeClass 'active'
        ])
        .directive('readonlyIf', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $scope.$watch attrs.readonlyIf, (val) ->
                    if val
                        element.addClass 'readonly'
                    else
                        element.removeClass 'readonly'
        ])
        .directive('delayed', ['$timeout', ($timeout) ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                going = null
                element.on 'keyup', (event)->
                    if event.which is 27 #escape
                        element.val ''
                    if going
                        $timeout.cancel going
                    going = $timeout (->
                        val = element.val()
                        $scope.$apply ->
                            $scope.$eval "#{attrs.delayed}='#{val}'"
                        ), ANIMATION_SPEED
                element.on 'blur', ->
                    #do this without signaling back to the scope
                    element.val ''
        ])
