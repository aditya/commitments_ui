#Markdown editor using codemirror
define ['angular',
    'lodash',
    'codemirror',
    'cs!src/editable'], (angular, _) ->
    PAD = 6
    module = angular.module('editable')
        .directive('markdown', ['$timeout', ($timeout) ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'markdown'
                codemirror = null
                attachTo = $ "<div></div>"
                attachTo.width('100%')
                attachTo.height('auto')
                attachTo.hide()
                display = $ "<div class='display'></div>"
                if attrs.multiline?
                    display.addClass 'multiline'
                else
                    display.addClass 'oneline'
                if attrs.readonlyIf?
                    $scope.$watch attrs.readonlyIf, (val) ->
                        if val
                            display.addClass 'readonly'
                        else
                            display.removeClass 'readonly'
                if attrs.readonly?
                    display.addClass 'readonly'
                element.append display, attachTo
                #these are the handlers that apply the edits
                whenOK = ->
                    if codemirror
                        if not codemirror.cancelEdit
                            value = codemirror.getValue().trimLeft().trimRight()
                            if value is ngModel.$viewValue
                                #no need to fire an edit if there is no change
                            else
                                $scope.$apply ->
                                    ngModel.$setViewValue(value)
                                    ngModel.$render()
                                    $scope.$emit 'edit', attrs.ngModel, value
                        attachTo.hide 100, ->
                            display.show 100
                            $('.CodeMirror', attachTo).remove()
                            codemirror = null
                forceBlur = ->
                    $('.CodeMirror', attachTo).remove()
                #hook on to any way in the field
                element.on 'click dblclick', () ->
                    if element.hasClass 'readonly'
                        return
                    #only hook up the editor if there isn't one
                    if not codemirror
                        codemirror = CodeMirror attachTo[0]
                        codemirror.setOption 'lineWrapping', true
                        $('.CodeMirror', attachTo).addClass 'editing'
                        #automatic expanding of size, no scrollbars
                        $('.CodeMirror-scroll', attachTo)
                            .css('overflow-x', 'auto')
                            .css('overflow-y', 'hidden')
                        $('.CodeMirror', attachTo).css('height', 'auto')
                        if attrs.multiline?
                            codemirror.setOption 'extraKeys',
                                'Ctrl-Enter': (cm) ->
                                    forceBlur()
                                Esc: (cm) ->
                                    codemirror.cancelEdit = true
                                    forceBlur()
                        else
                            #trap enter, preventing multiple lines being added
                            #yet still allow 'wrapped' single line to be
                            #visually multiple lines in the DOM
                            codemirror.setOption 'extraKeys',
                                'Ctrl-Enter': (cm) ->
                                    forceBlur()
                                Enter: (cm) ->
                                    forceBlur()
                                Down: (cm) ->
                                    #supress, not allowing line navigation
                                    null
                                Esc: (cm) ->
                                    codemirror.cancelEdit = true
                                    forceBlur()
                        codemirror.on 'blur', ->
                            whenOK()
                        codemirror.setValue ngModel.$viewValue or ''
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
