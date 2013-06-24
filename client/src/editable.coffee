define ['md5',
    'moment',
    'lodash',
    'marked'
    'codemirrormarkdown',
    'jquery-sortable'
    ], (md5, moment, _, marked) ->
    counter = 0;
    AUTOSAVE_DELAY = 5000
    ANIMATION_SPEED = 200
    #sizer element, this is used for font relative treachery
    measureTextWidth = (element) ->
        sizer = $('#editSizer')
        if not sizer.length
            sizer = $(document).append($("<div id='editSizer'/>")).find("#editSizer")
        style = element[0].currentStyle or window.getComputedStyle(element[0], null)
        sizer.css({
            position: "absolute",
            left: "-10000px",
            top: "-10000px",
            display: "none",
            margin: style.margin,
            padding: style.padding,
            fontSize: style.fontSize,
            fontFamily: style.fontFamily,
            fontStyle: style.fontStyle,
            fontWeight: style.fontWeight,
            letterSpacing: style.letterSpacing,
            textTransform: style.textTransform,
            whiteSpace: "nowrap"
        })
        sizer.text(element.text() + '__')
        console.log sizer
        sizer.width()
    module = angular.module('editable', ['Root'])
        .directive('editableRecord', ['$timeout', ($timeout) ->
            scope: true
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'editableRecord'
                #record hove tracking
                $scope.hover = false
                element.hover (->
                    $scope.hover = true
                    $scope.$emit 'hover', true, ngModel.$modelValue
                    $scope.$digest()
                ), (->
                    $scope.hover = false
                    $scope.$emit 'hover', false, ngModel.$modelValue
                    $scope.$digest()
                )
                #hang on to the data in jquery
                $scope.$watch attrs.ngModel, (model) ->
                    element.data 'record', model
                #explicit click to select
                element.on 'click', (event) ->
                    event.stopPropagation()
                    #tell the parent list all about it
                    $scope.$apply ->
                        $scope.$emit 'selectrecord', ngModel.$modelValue
                #listening for the focus event, in order to bind
                #entended/hidden properties, this is coming 'down' from the
                #parent list
                $scope.$on 'selectedrecord', (event, data) ->
                    if data is ngModel.$modelValue
                        $scope.focused = true
                        console.log data
                        #may need to digest, and only on the focus, the unfocsed
                        #things will get covered in the same digest loop implicitly
                    else
                        $scope.focused = false
                    if not $scope.$$phase
                        $scope.$digest()
                $scope.$on 'deselect', (event) ->
                    $scope.focused = false
                $scope.$on 'edit', ->
                    if attrs.editableRecord
                        $scope.$emit attrs.editableRecord, ngModel.$modelValue
        ])
        #placeholders give you a spot to enter new records
        .directive('editableRecordPlaceholder', [() ->
            restrict: 'A'
            require: 'ngModel'
            priority: 100
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'editableRecordPlaceholder'
                if not $scope.$$placeholder
                    $scope.$$placeholder = {}
                #on an edit, treat this as a real record
                $scope.$on 'edit', (event) ->
                    event.stopPropagation()
                    #new record is ready, emit events on pu the chain
                    $scope.$emit 'newrecord', $scope.$$placeholder
                    #and a fresh placeholder
                    $scope.$$placeholder = {}
        ])
        #nestedLists have special delete behavior
        .directive('editableListNested', [ ->
            restrict: 'A'
            require: 'ngModel'
            priority: 200
            link: ($scope, element, attrs, ngModel) ->
                $scope.$on 'deleterecord', (event, record) ->
                    event.stopPropagation()
                    #hunt for nested records all the way down
                    prune = (record, list) ->
                        foundAt = list.indexOf(record)
                        if foundAt >= 0
                            list.splice(foundAt, 1)
                            #and with an item removed, the list itself is updated
                            #in place via the splice
                            $scope.$emit 'edit'
                        else
                            for item in list
                                prune record, item.subitems or []
                    prune record, ngModel.$modelValue
                #nested lists update the record itself, then propagate an
                #edit once we know that data is saved into the object
                $scope.$on 'reorder', (event, items) ->
                    ngModel.$setViewValue items
                    $scope.$emit 'edit'
        ])
        #equip a list with drag and drop reordering, used ot stack rank tasks
        .directive('editableListReorder', [ '$rootScope', ($rootScope) ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                id = md5("#{Date.now()}#{counter++}")
                element.sortable
                    group: id
                    handle: attrs.dragHandle or '.handle'
                    nested: attrs.editableListNested?
                    placeholder: '<li class="icon-chevron-right placeholder"/>'
                    onDragStart: ($item, container, _super) ->
                        $scope.sorting = true
                        element.addClass 'sorting'
                        $scope.$apply ->
                            $scope.$broadcast 'deselect'
                        _super $item, container
                    onDrop: ($item, targetContainer, _super) ->
                        $scope.sorting = false
                        element.removeClass 'sorting'
                        new_order = []
                        serialized = element.sortable('serialize')
                        recurse = (buffer, source) ->
                            for o in (source or [])
                                if o?.$scope?.$$placeholder is o?.record
                                    #skip
                                else if o.record
                                    buffer.push o.record
                                    if attrs.editableListNested?
                                        #new blank buffer, as this may be empty now
                                        o.record.subitems = []
                                        recurse o.record.subitems, o.children
                        recurse new_order, serialized
                        if attrs.onReorder
                            $scope.$apply ->
                                $scope.$eval(attrs.onReorder) new_order
                        else
                            $scope.$apply ->
                                $scope.$emit 'reorder', new_order
                        _super $item, targetContainer
                    isValidTarget: (item, container, totalSlots, toSlot) ->
                        #if there is a placeholder we can't drag to the last record
                        #as that makes an odd visual layout. this has the effect
                        #of keeping the placeholder last
                        if element.find('.editableRecordPlaceholder').length
                            (toSlot + 1) < totalSlots
                        else
                            true
                $scope.$on 'newrecord', (event, model) ->
                    if model is ngModel.$modelValue
                        ngModel.$modelValue.push id: md5("#{Date.now()}")
        ])
        #drag handles give off events to inform draggable lists
        .directive('handle', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.addClass 'handle'
                #drag handles need to show when you are in the item, and hide
                #when you leave the item
                $scope.$watch 'hover', (hovering) ->
                    if hovering
                        #...but not show on items you drag over, that would be silly
                        #so if we are already sorting, hovered over handles are hidden still
                        if not $scope.sorting
                            element.removeClass 'flipOutX'
                            element.addClass 'animated flipInX'
                    else
                        #do not hide the drag handles while dragging, otherwise
                        #the dragged objects look weak
                        if not $scope.sorting
                            element.removeClass 'flipInX'
                            element.addClass 'animated flipOutX'
        ])
        .directive('editableList', ['$timeout', ($timeout) ->
            scope: true
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'editablelist'
                #make sure there is always a list if we change models
                $scope.$watch attrs.ngModel, (model) ->
                    if not ngModel.$viewValue
                        ngModel.$setViewValue([])
                #this is a relay event from contained records up to this list
                #tell all the child records that there has been a selection
                #so they can hide themselves, unbind, etc.
                $scope.$on 'selectrecord', (event, record) ->
                    event.stopPropagation()
                    $scope.$broadcast 'selectedrecord', record
                #when there is a new record, add it into the current view model
                $scope.$on 'newrecord', (event, record) ->
                    event.stopPropagation()
                    #push to the underlying model, new records start at the end
                    list = ngModel.$modelValue
                    list.push record
                    $timeout ->
                        $scope.$broadcast 'selectedrecord', record
                    if attrs.editableListNew
                        $scope.$emit attrs.editableListNew, record
                    $scope.$emit 'edit'
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
        #ahh tagging!
        .directive('editableTags', [ ->
            restrict: 'A'
            require: 'ngModel'
            scope: true
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'tags'
                #events, coming on up
                #emit an edit to let the containing record save
                $scope.$on 'add', (event, tag) ->
                    event.stopPropagation()
                    ngModel.$modelValue[tag] = Date.now()
                    $scope.$emit 'edit'
                $scope.$on 'delete', (event, tag) ->
                    event.stopPropagation()
                    delete ngModel.$modelValue[tag]
                    $scope.$emit 'edit'
        ])
        #user input to allow tag entry and add into a model
        .directive('autocompleteTagger', [ ->
            restrict: 'A'
            require: '^ngModel'
            link: ($scope, element, attrs, ngModel) ->
                #setup
                element.addClass 'autocomplete-tagger'
                #this is nice, makes it self resize unlike an input
                element.attr 'contentEditable', true
                #poking under the hood to angular bind the data source
                typeahead = element.typeahead().data('typeahead')
                $scope.$watch attrs.autocompleteTagger, (autocomplete) ->
                    typeahead.source = (query) ->
                        ret = autocomplete()
                        ret.unshift query
                        ret
                #events
                element.on 'focus', (event) ->
                    $scope.$apply ->
                        $scope.tagEditing = true
                element.on 'blur', (event) ->
                    #never hold on to old value
                    element.val('')
                    $scope.$apply ->
                        $scope.tagEditing = false
                element.on 'keyup', (event) ->
                    #here is an odd one, it is easy to end up with a lot of &nbsp;
                    #so that should really be blank
                    if element.val().trim() is ''
                        element.val('')
                    #force blur on escape
                    if event.keyCode is 27
                        element.blur()
                #and here is the real action
                element.on 'change', ->
                    #tag value is sent along to the enclosing tag
                    tag = element.val().trim()
                    element.val('')
                    $scope.$apply ->
                        $scope.$emit 'add', tag
        ])
        .directive('check', [ ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                    icon = angular.element("<i/>")
                    element.addClass 'check'
                    element.append(icon)
                    readonly = false
                    $scope.$watch 'readonly', (ro) ->
                        readonly = ro
                        if ro
                            element.addClass 'readonly'
                        else
                            element.removeClass 'readonly'
                    element.on 'click', ->
                        if readonly
                            #no action
                        else
                            if ngModel.$viewValue
                                value = 0
                            else
                                value = Date.now()
                            $scope.$apply () ->
                                ngModel.$setViewValue value
                                ngModel.$render()
                                $scope.$emit 'edit', attrs.ngModel, ngModel
                    ngModel.$render = ->
                        icon.removeClass 'icon-check'
                        icon.addClass 'icon-check-empty'
                        if ngModel.$viewValue
                            icon.addClass 'icon-check'
                            icon.removeClass 'icon-check-empty'
        ])
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
                #grab the focus and push it through to a codemirror
                element.on 'click dblclick focus spanfocus', (event) ->
                    if not display.hasClass 'readonly'
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
