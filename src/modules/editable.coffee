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

            icon.bind 'click', (event) ->
                picker = angular.element('<div/>')
                touchup = (picker) ->
                    console.log 'a'
                    $('.ui-datepicker-next', picker).append ('<div class="icon-chevron-right"/>')
                    $('.ui-datepicker-prev', picker).append ('<div class="icon-chevron-left"/>')
                picker.datepicker
                    onSelect: (date, picker) ->
                        icon.popover 'destroy'
                        $scope.$apply () ->
                            ngModel.$setViewValue date
                            ngModel.$render()
                    onChangeMonthYear:  (year, month, o) ->
                        console.log o, year, month
                        setTimeout -> touchup(o)
                icon.popover {content: picker, html: true, placement: 'bottom'}
                icon.popover 'show'
            ngModel.$render = () ->
                console.log 'render', ngModel
                display.text ngModel.$viewValue
    ])


