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
                attachTo.hide()
                display = $ "<div class='display'></div>"
                if attrs.multiline?
                    display.addClass 'multiline'
                else
                    display.addClass 'oneline'
                buttons = $ """
                <div class="btn-group">
                    <button class="ok btn"><i class="icon-ok"></i></button>
                    <button class="cancel btn"><i class="icon-ban-circle"></i></button>
                </div>
                """
                buttons.hide()
                element.append display, attachTo, buttons
                #these are the handlers that apply the edits
                whenOK = ->
                    value = codemirror.getValue().trimLeft().trimRight()
                    if value is ngModel.$viewValue
                        #no need to fire an edit if there is no change
                    else
                        $scope.$apply ->
                            ngModel.$setViewValue(value)
                            ngModel.$render()
                            $scope.$emit 'edit', attrs.ngModel, value
                    display.show 100
                    buttons.hide 100
                    attachTo.hide 100, ->
                        codemirror = null
                        $('.CodeMirror', attachTo).remove()
                whenCancel = ->
                    display.show 100
                    buttons.hide 100
                    attachTo.hide 100, ->
                        codemirror = null
                        $('.CodeMirror', attachTo).remove()
                #handle the buttons
                element.on 'click', '.ok', ->
                    console.log 'ok'
                    whenOK()
                element.on 'click', '.cancel', ->
                    console.log 'cancel'
                    whenCancel()
                #hook on to any way in the field
                element.on 'click dblclick focus', () ->
                    if element.hasClass 'readonly'
                        return
                    #only hook up the editor if there isn't one
                    if not codemirror
                        attachTo.width('100%')
                        codemirror = CodeMirror attachTo[0]
                        codemirror.setOption 'lineWrapping', true
                        $('.CodeMirror', attachTo).addClass 'editing'
                        buttons.show()
                        if attrs.multiline?
                            attachTo.height('auto')
                            #automatic expanding of size
                            $('.CodeMirror-scroll', attachTo)
                                .css('overflow-x', 'auto')
                                .css('overflow-y', 'hidden')
                            $('.CodeMirror', attachTo).css('height', 'auto')
                            codemirror.setOption 'extraKeys',
                                'Ctrl-Enter': (cm) ->
                                    whenOK()
                                    null
                                Esc: (cm) ->
                                    whenCancel()
                                    null
                        else
                            #deferred sizing to give code mirror a chance to figure font
                            $('.CodeMirror', attachTo).css('height', codemirror.defaultTextHeight())
                            $timeout ->
                                $('.CodeMirror', attachTo).css('height', codemirror.defaultTextHeight() + PAD)
                            #trap enter, preventing multiple lines being added
                            #yet still allow 'wrapped' single line to be
                            #visually multiple lines in the DOM
                            codemirror.setOption 'extraKeys',
                                'Ctrl-Enter': (cm) ->
                                    whenOK()
                                    null
                                Enter: (cm) ->
                                    whenOK()
                                    null
                                Down: (cm) ->
                                    #supress, not allowing line navigation
                                    null
                                Esc: (cm) ->
                                    whenCancel()
                                    null
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
