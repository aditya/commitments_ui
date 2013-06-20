#Markdown editor using codemirror
define ['angular',
    'lodash',
    'marked'
    'codemirrormarkdown',
    'cs!src/editable'], (angular, _, marked) ->
    AUTOSAVE_DELAY = 5000
    ANIMATION_SPEED = 200
    module = angular.module('editable')
        .directive('renderMarkdown', ['$timeout', ($timeout) ->
            restrict: 'A'
            require: '?ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'markdown'
                if ngModel
                    $scope.$watch attrs.ngModel, (text) ->
                        element.html marked(text)
                else
                    element.html marked(element.text())
        ])
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
                display = $ "<div class='display collapsed'></div>"
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
                twizzlerMore = $('<span class="twizzler icon-double-angle-right"></span>').hide()
                twizzlerMore.on 'click', ->
                    display.removeClass 'collapsed', ANIMATION_SPEED
                    twizzlerMore.hide()
                    twizzlerLess.show()
                twizzlerLess = $('<span class="twizzler icon-double-angle-left"></span>').hide()
                twizzlerLess.on 'click', ->
                    display.addClass 'collapsed', ANIMATION_SPEED
                    twizzlerLess.hide()
                    twizzlerMore.show()
                element.append twizzlerLess, twizzlerMore
                #these are the handlers that apply the edits
                save = ->
                    if codemirror and not codemirror.cancelEdit?
                        value = codemirror.getValue().trimLeft().trimRight()
                        if value is ngModel.$viewValue
                            #no need to fire an edit if there is no change
                        else if (not value) and (not ngModel.$viewValue)
                            #the un-fun empty equals
                        else
                            ngModel.$setViewValue(value)
                            $scope.$apply ->
                                $scope.$emit 'edit'
                #blur handling is the main way to save and re-render
                forceBlur = ->
                    save()
                    if codemirror
                        #unhook the guard first, otherwise we can double blur
                        #when using a hotkey
                        codemirror = null
                        attachTo.hide ANIMATION_SPEED, ->
                            $('.CodeMirror', attachTo).remove()
                            $scope.$apply ->
                                ngModel.$render()
                            display.show ANIMATION_SPEED
                #hook on to any way in the field
                focus = ->
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
                                    if attrs.escapeToCancel?
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
                                    if attrs.escapeToCancel?
                                        codemirror.cancelEdit = true
                                    forceBlur()
                        codemirror.setValue ngModel.$viewValue or ''
                        codemirror.on 'blur', ->
                            forceBlur()
                        if attrs.noAutosave?
                            #nothing to do here just yet
                        else
                            codemirror.on 'change', _.debounce(save, AUTOSAVE_DELAY)
                        display.hide 100
                        attachTo.show 100, ->
                            codemirror.focus()
                            codemirror.setOption('mode', 'markdown')
                            codemirror.setOption('theme', 'neat')
                            codemirror.refresh()
                #event that might trigger a forced focus
                if attrs.focusOn?
                    element.scope().$on attrs.focusOn, ->
                        focus()
                #grab the focus and push it through to a codemirror
                element.on 'click dblclick', (event) ->
                    if not display.hasClass 'readonly'
                        focus()
                element.on 'focus', (event) ->
                    focus()
                #markdown rendering with optional search word highlighting
                if attrs.searchHighlight
                    hilightCount = 0
                    $scope.$watch attrs.searchHighlight, (value) ->
                        if hilightCount++ > 0
                            ngModel.$render()
                ngModel.$render = () ->
                    #markdown based display
                    content = ngModel.$viewValue or ''
                    if attrs.searchHighlight
                        search = $scope.$eval(attrs.searchHighlight)
                        if search
                            for word in search.split(' ')
                                word = word.trim()
                                content =
                                   content.replace(
                                       new RegExp(word, 'gi'),
                                       '<span class="highlight">$&</span>')
                    rendered = marked content
                    display.html rendered
                    placeholder = $scope.$eval(attrs.placeholder) or "..."
                    #placeholder text
                    if ngModel.$viewValue
                        display.removeClass('placeholder')
                    else
                        display.addClass('placeholder')
                        display.html(placeholder)
                    if attrs.multiline?
                        setTimeout ->
                            if display[0].offsetHeight < display[0].scrollHeight
                                twizzlerMore.show()
                            else
                                twizzlerMore.hide()
                        , ANIMATION_SPEED
        ])
