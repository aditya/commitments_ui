###
Inline edit capabilities are captured here. These depend on
* FontAwesome
* jQuery
* widgets

The idea is to create a set of data input components that are not FORM based
in any way.

Editable Text
-------------
Put this on a block element, with ng-model indicating the binding target:

    <div editable-text ng-model="item.message"></div>

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

Attributes:
    focus-on-add
        when specified, set the focus here to start editing right away

Editable Check
--------------
Put this on a block elemnt, it makes a nice checkbox binding to a boolean.

    <div editable-check ng-model="item.done"></div>
###

AUTOHIDE_DELAY = 3000

module = angular.module('editable', [])
    .directive('editableRecord', [() ->
        restrict: 'A'
        link: ($scope, element) ->
            element.bind 'click dblclick focus', (e) ->
                if element[0] is e.target
                    $scope.$broadcast 'inRecord'
    ])
    .directive('editableText', [() ->
        restrict: 'A'
        require: 'ngModel'
        link: ($scope, element, attrs, ngModel) ->
            element.bind 'blur', () ->
                $scope.$apply () ->
                    ngModel.$setViewValue(element.text())
                    if attrs.deleteWhenBlank? and not ngModel.$viewValue
                        $scope.$emit 'deleteWhenBlank', $scope.$eval(attrs.deleteWhenBlank)
            element.bind 'keydown', (event) ->
                if event.which is 27 #escape
                    event.target.blur()
                    event.preventDefault()
            ngModel.$render = () ->
                if ngModel.$viewValue?
                    element.text ngModel.$viewValue
                else
                    if attrs.focusOnAdd?
                        element.focus()
            $scope.$on 'inRecord', ->
                if attrs.focusOnAdd?
                    element.focus()

            element.attr 'contentEditable', true
            element.addClass 'editableText'
    ])
    .directive('editableList', [() ->
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
            #handle propagated deletes, this will be in an apply
            $scope.$on 'deleteWhenBlank', (event, item) ->
                list = ngModel.$modelValue
                list.splice(list.indexOf(item), 1)


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
    .directive('editableComment', [ ->
        restrict: 'A'
        require: 'ngModel'
        compile: (templateElement, templateAttrs) ->
            surround = angular.element("<div class='editableComment popover right'/>")
            arrow = angular.element("<div class='arrow'/>")
            surround.append(arrow)
            templateElement.append(surround)
            ($scope, element, attrs, ngModel) ->
                display = angular.element("<div class='editableCommentDisplay'/>")
                console.log element.find '.editableComment'
                element.find('.editableComment').append(display)
                ngModel.$render = ->
                    display.text ngModel.$viewValue
    ])
