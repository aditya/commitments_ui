###
Inline edit capabilities are captured here. The idea is to enable bound
angular JS editing without resorting to the use of a FORM or any server trip.

Editable Record
---------------
Marker you put on a repeater or container. This will broadcast an event down
when you click in the non-field areas of a record, useful to make it really
easy to start editing without having to aim the mouse precisely at fields.

Editable Markdown
-----------------
Put this on a block element, with ng-model indicating the binding target:

    <div editable-markdown ng-model="item.message"></div>

Attributes:
    focus-on-add
        when specified, set the focus here to start editing right away
    delete-when-blank
        when specified, fires an event up the scope to allow containing lists
        a chance to remove the item

Editable List
-------------
Put this on a list, with ng-model indicating the binding target:

    <ul editable-list ng-model="selected.items">

Editable Check
--------------
Put this on a block elemnt, it makes a nice checkbox binding to a boolean.

    <div editable-check ng-model="item.done"></div>
###


module = angular.module('editable', [])
    .directive('editableRecord', [() ->
        restrict: 'A'
        link: ($scope, element) ->
            element.bind 'click dblclick focus', (e) ->
                if element[0] is e.target
                    $scope.$broadcast 'inRecord'
    ])
    .directive('editableMarkdown', ['$timeout', ($timeout) ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.addClass 'editableMarkdown'
            attachTo = angular.element("<div></div>")
            attachTo.hide()
            display = angular.element("<div class='display'></div>")
            element.append display, attachTo
            codemirror = null
            #hook on to any way in the field
            element.bind 'click dblclick focus', () ->
                console.log 'focus'
                if not codemirror
                    codemirror = CodeMirror attachTo[0]
                    attachTo.width('100%')
                    $('.CodeMirror', attachTo).css('height', 'auto')
                    $('.CodeMirror-scroll', attachTo)
                        .css('overflow-x', 'auto')
                        .css('overflow-y', 'hidden')
                    codemirror.on 'blur', ->
                        $scope.$apply ->
                            value = codemirror.getValue().trimLeft().trimRight()
                            if attrs.deleteWhenBlank? and value is ""
                                $scope.$emit 'delete', $scope.$eval(attrs.deleteWhenBlank)
                            else
                                #clear the placeholder flag, this is now a record
                                $scope.$eval?(attrs.deleteWhenBlank).$$placeholder = false
                                ngModel.$setViewValue(value)
                                ngModel.$render()
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
                else if attrs.focusOnAdd?
                    element.click()
            #additional autofocus support
            $scope.$on 'inRecord', ->
                if attrs.focusOnAdd?
                    element.click()
    ])
    .directive('editableList', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            $scope.$watch attrs.ngModel, ->
                #make sure there is always a list
                if not ngModel.$viewValue
                    ngModel.$setViewValue([])
            #handle propagated deletes, this will be in an apply
            $scope.$on 'delete', (event, item) ->
                list = ngModel.$modelValue
                foundAt = list.indexOf(item)
                if foundAt >= 0
                    list.splice(foundAt, 1)
    ])
    .directive('editableListAdd', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            #provide UI handling to add items
            wrapped = element.wrap('<div class="editableList"/>').parent()
            adder = angular.element('<div class="editableListAdd icon-plus"/>')
            wrapped.append(adder)
            adder.bind 'click', () ->
                $scope.$apply () ->
                    ngModel.$modelValue.push({})
    ])
    .directive('editableListBlankRecord', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            listDiffers = (model) ->
                tail = model.slice(-1)?[0]
                console.log 'check placeholder', tail
                if tail and tail.$$placeholder
                    #there is already a placeholder record
                else
                    console.log 'blank record'
                    model.push
                        $$placeholder: true
            $scope.$watch attrs.ngModel, listDiffers, true
    ])
    .directive('editableRecord', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            updateCount = 0
            recordDiffers = (model) ->
                console.log 'edited', model, updateCount++
            $scope.$watch attrs.ngModel, recordDiffers, true
    ])
    .directive('editableDate', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.addClass 'editableDate'
            icon = angular.element('<span class="icon-calendar editableDateIcon"/>')
            display = angular.element('<span class="editableDateDisplay"/>')
            element.append(icon, display)
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
            ngModel.$render = () ->
                if not ngModel.$viewValue
                    ngModel.$setViewValue(moment().format())
                display.text ngModel.$viewValue
    ])
    .directive('editableTags', ['$timeout', ($timeout) ->
        restrict: 'A'
        require: 'ngModel'
        compile: (templateElement, templateAttrs) ->
            templateElement.addClass 'editableTags'
            templateAttrs.icon = templateAttrs.icon or 'tags'
            icon = angular.element("<span class='icon-#{templateAttrs.icon} editableTagsIcon'/>")
            display = angular.element('<span class="editableTagsDisplay"/>')
            templateElement.append(icon, display)
            ($scope, element, attrs, ngModel) ->
                element.on 'keydown', (event) ->
                    if event.which is 27 #escape
                        document.activeElement.blur()
                icon = $('.editableTagsIcon', element)
                input = $('.editableTagsDisplay', element)
                icon.bind 'click', ->
                    input.tagbar 'focusSearch'
                input.tagbar
                    tagSeparators: [',', '\\s']
                    tagNamespaceSeparators: ['/', ':']
                    query: (query) ->
                        query.callback
                            results: [query.term, 'sample']
                #just propagate tag values back to the model
                element.bind 'change', () ->
                    ngModel.$setViewValue(input.tagbar('val'))
                #rendering is really just setting the values
                ngModel.$render = () ->
                    input.tagbar 'val',  ngModel.$viewValue or []
    ])
    .directive('editableCheck', [ ->
        restrict: 'A'
        require: 'ngModel'
        compile: (templateElement, templateAttrs) ->
            ($scope, element, attrs, ngModel) ->
                icon = angular.element("<span class='editableCheckIcon'/>")
                element.append(icon)
                element.bind 'click', ->
                    $scope.$apply () ->
                        ngModel.$setViewValue not(ngModel.$viewValue or false)
                        ngModel.$render()
                ngModel.$render = ->
                    icon.removeClass 'icon-check'
                    icon.addClass 'icon-check-empty'
                    if ngModel.$viewValue
                        icon.addClass 'icon-check'
                        icon.removeClass 'icon-check-empty'
    ])
