#Markdown editor using codemirror
define ['angular',
    'lodash',
    'codemirror',
    'cs!src/editable'], (angular, _) ->
    module = angular.module('editable')
        .directive('markdown', ['$timeout', ($timeout) ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'markdown'
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
                        event.stopPropagation()
                ngModel.$render = () ->
                    #markdown based display
                    if ngModel.$viewValue
                        display.removeClass('placeholder')
                        display.html(markdown.toHTML(ngModel.$viewValue))
                    else if attrs.placeholder
                        display.addClass('placeholder')
                        display.html($scope.$eval(attrs.placeholder))
        ])
