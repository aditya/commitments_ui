
counter = 0;

ANIMATION_SPEED = 200

module = angular.module('editable', [])
    .directive('editableRecord', [() ->
        scope: true
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            $scope.$watch attrs.ngModel, (model) ->
                #fields that are always required
                if not model.id
                    model.id = md5("#{Date.now()}#{counter++}")
                if not model.who
                    model.who = $scope.user.email
                if model.$$required
                    if not model.when
                        model.when = Date.now()
                #controller callback with the updated item
                if attrs.onUpdate
                    $scope.$eval(attrs.onUpdate) model
                $scope.$emit 'editableRecordUpdate', model
            ,true
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
                element.sortable
                    handle: attrs.handle
                element.on 'mouseenter', 'li', (event) ->
                    $(attrs.handle, $(event.currentTarget)).animate
                        opacity: 1
                    , ANIMATION_SPEED
                element.on 'mouseleave', 'li', (event) ->
                    $(attrs.handle, $(event.currentTarget)).animate
                        opacity: 0
                    , ANIMATION_SPEED
            else
                element.sortable {}
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
                    ngModel.$modelValue.$$placeholder = {}
                    ngModel.$modelValue.push ngModel.$modelValue.$$placeholder
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
            element.append display, attachTo
            codemirror = null
            #hook on to any way in the field
            element.bind 'click dblclick focus', () ->
                if element.hasClass 'readonly'
                    return
                if not codemirror
                    codemirror = CodeMirror attachTo[0]
                    codemirror.setOption 'lineWrapping', true
                    attachTo.height('auto')
                    $('.CodeMirror', attachTo).css('height', 'auto')
                    $('.CodeMirror-scroll', attachTo)
                        .css('overflow-x', 'auto')
                        .css('overflow-y', 'hidden')
                    if attrs.multiline?
                        #fill up the allocated space, this is more like a
                        #textarea in this case, rather than just an self
                        #expanding field
                        attachTo.width('100%')
                    else
                        #trap enter, preventing multiple lines being added
                        #yet still allow 'wrapped' single line to be
                        #visually multiple lines in the DOM
                        codemirror.setOption 'extraKeys',
                            Enter: (cm) ->
                                #hard core trigger a blur
                                $('.CodeMirror', attachTo).remove()
                    codemirror.on 'blur', ->
                        console.log 'blur', codemirror
                        value = codemirror.getValue().trimLeft().trimRight()
                        ngModel.$setViewValue(value)
                        ngModel.$render()
                        $scope.$digest()
                        $timeout ->
                            display.show 100
                            attachTo.hide 100, ->
                                codemirror = null
                                $('.CodeMirror', attachTo).remove()
                codemirror.setValue ngModel.$viewValue or '\n'
                display.hide 100
                attachTo.show 100, ->
                    codemirror.focus()
                    codemirror.setOption('mode', 'markdown')
                    codemirror.setOption('theme', 'neat')
                    codemirror.refresh()
            element.bind 'keydown', (event) ->
                if event.which is 27 #escape
                    event.target.blur()
                    event.preventDefault()
            ngModel.$render = () ->
                #markdown based display
                if ngModel.$viewValue
                    display.removeClass('placeholder')
                    display.html(markdown.toHTML(ngModel.$viewValue))
                else if attrs.placeholder
                    display.addClass('placeholder')
                    display.html($scope.$eval(attrs.placeholder))
    ])
    .directive('date', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.addClass 'date'
            element.addClass 'editable'
            icon = angular.element('<span class="icon-calendar icon"/>')
            display = angular.element('<span class="date-display"/>')
            deleter = angular.element('<span class="icon icon-remove-sign deleter"/>')
            element.append(icon, display, deleter)
            #make sure to unhook the dialog like keyboard capture
            clearCapture = ->
                icon.popover 'destroy'
                $(document).off 'keydown.editableDate'
                $(document).off 'mousedown.editableDate'
            #entire field is editable, just click it
            startEdit = (event) ->
                picker = angular.element('<div/>')
                picker.datepicker
                    prevText: ''
                    nextText: ''
                    onSelect: (date, picker) ->
                        clearCapture()
                        $scope.$apply () ->
                            ngModel.$setViewValue date
                            ngModel.$render()
                $(document).on 'keydown.editableDate', (event) ->
                    if event.which is 27 #escape
                        clearCapture()
                    event.stopPropagation()
                $(document).on 'mousedown.editableDate', (event) ->
                    parent = event.originalEvent.target
                    while parent
                        parent = parent.parentElement
                        if parent is picker[0]
                            return
                    clearCapture()
                icon.popover {content: picker, html: true, placement: 'bottom'}
                icon.popover 'show'
            icon.bind 'click', startEdit
            display.bind 'click', startEdit
            deleter.bind 'click', ->
                $scope.$apply ->
                    ngModel.$setViewValue('')
                    ngModel.$render()
            ngModel.$render = () ->
                if ngModel.$viewValue
                    deleter.show()
                else
                    deleter.hide()
                display.text ngModel.$viewValue
    ])
    .directive('tags', ['$timeout', ($timeout) ->
        restrict: 'A'
        require: 'ngModel'
        compile: (templateElement, templateAttrs) ->
            templateElement.addClass 'tags'
            templateElement.addClass 'editable'
            templateAttrs.icon = templateAttrs.icon or 'tags'
            ($scope, element, attrs, ngModel) ->
                input = angular.element('<span class="tag-display"/>')
                element.append input
                input.tagbar
                    icon: templateAttrs.icon
                    tagSeparators: [',', ';']
                    tagNamespaceSeparators: $scope.tagNamespaceSeparators
                    query: (query) ->
                        query.callback
                            results: [query.term, 'sample']
                #just propagate tag values back to the model
                input.bind 'blur change', (event) ->
                    console.log event, input.tagbar('val')
                    ngModel.$setViewValue(input.tagbar('val'))
                #rendering is really just setting the values
                ngModel.$render = () ->
                    if not ngModel.$viewValue
                        ngModel.$setViewValue {}
                    input.tagbar 'val', ngModel.$viewValue
                watchCount = 0
                $scope.$watch attrs.ngModel, (->
                    if watchCount++
                        ngModel.$render()
                ), true
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
                element.bind 'click', ->
                    $scope.$apply () ->
                        if ngModel.$viewValue
                            ngModel.$setViewValue ''
                        else
                            ngModel.$setViewValue Date.now()
                        ngModel.$render()
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
            if not $scope.$eval(attrs.requiresObject)
                $scope.$eval("#{attrs.requiresObject}={}")
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
