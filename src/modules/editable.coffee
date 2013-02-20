###
Inline edit capabilities are capture here. Just add these to supported tags.

Editable Text
-------------
Put this on a div, with ng-model indicating the binding target:

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
###
module = angular.module('editable', [])
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

            clearCapture = ->
                icon.popover 'destroy'
                $(document).off 'keydown.editableDate'
                $(document).off 'mousedown.editableDate'

            icon.bind 'click', (event) ->

                picker = angular.element('<div/>')
                picker.datepicker
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
            ngModel.$render = () ->
                display.text ngModel.$viewValue
    ])
    .directive('editableTags', ['$timeout', ($timeout) ->
        restrict: 'A'
        require: 'ngModel'
        compile: (templateElement, templateAttrs) ->
            templateElement.addClass 'editableTags'
            templateAttrs.icon = templateAttrs.icon or 'tags'
            console.log templateAttrs
            icon = angular.element("<span class='icon-#{templateAttrs.icon} editableTagsIcon'/>")
            display = angular.element('<input type="hidden" class="editableTagsDisplay"/>')
            templateElement.append(icon, display)
            ($scope, element, attrs, ngModel) ->
                element.on 'keydown', (event) ->
                    if event.which is 27 #escape
                        document.activeElement.blur()
                icon = $('.editableTagsIcon', element)
                input = $('.editableTagsDisplay', element)
                icon.bind 'click', ->
                    $('.select2-input', element).focus()
                input.select2
                    tokenSeparators: [',', ' ']
                    multiple: true
                    createSearchChoice: (term) ->
                        id: term
                        text: term
                    initSelection: (element, callback) ->
                        ret = []
                        for _ in (ngModel.$viewValue or [])
                            ret.push
                                id: _
                                text: _
                        callback ret
                    query: (query) ->
                        ret =
                            results: [
                                id: query.term
                                text: query.term
                            ,
                                id: 'sample'
                                text: 'sample'
                            ]
                        query.callback ret

                #just propagate tag values back to the model
                element.bind 'change', () ->
                    ngModel.$setViewValue(input.select2('val'))
                    $('input', element).removeClass 'select2-active'
                    console.log ngModel.$viewValue

                #rendering is really just setting the values
                ngModel.$render = () ->
                    input.select2 'val',  ngModel.$viewValue or []
    ])



