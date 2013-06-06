define ['md5',
    'moment',
    'lodash',
    'jquery-sortable'
    ], (md5, moment, _) ->
    counter = 0;
    ANIMATION_SPEED = 200
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
                #fields that are always required
                $scope.$watch attrs.ngModel, (model) ->
                    if model
                        if not model.id
                            model.id = md5("#{Date.now()}#{counter++}")
                        if not model.who
                            model.who = $scope.user.email
                        if not model.when
                            model.when = Date.now()
                    element.data 'record', model
                element.on 'click', (event) ->
                    event.stopPropagation()
                    #tell the parent list all about it
                    $scope.$emit 'selectrecord', ngModel.$modelValue
                #a record may be focused when it is first created, specifically
                #when it is new, and this needs to be deferred to give ngmodel
                #a chance to bind up
                $timeout ->
                    if $scope.selectedrecord is ngModel.$modelValue
                        $scope.focused = true
                    else
                        $scope.focused = false
                #listening for the focus event, in order to bind
                #entended/hidden properties, this is coming 'down' from the
                #parent list
                $scope.$on 'selectedrecord', (event, data) ->
                    if data is ngModel.$modelValue
                        $scope.focused = true
                        #may need to digest, and only on the focus, the unfocsed
                        #things will get covered in the same digest loop implicitly
                    else
                        $scope.focused = false
                    if not $scope.$$phase
                        $scope.$digest()
                $scope.$on 'deselect', ->
                    $scope.focused = false
                #look for field level edits, in which case this record was
                #update so send along an event
                $scope.$on 'edit', (event) ->
                    event.stopPropagation()
                    $scope.$emit 'updaterecord', ngModel.$modelValue
                #a nested record perhaps? re-emit for this record
                $scope.$on 'updaterecord', (event, record) ->
                    if record isnt ngModel.$modelValue
                        event.stopPropagation()
                        $scope.$emit 'updaterecord', ngModel.$modelValue
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
                    #if we have a callback defined to work on any new item, call
                    #it now to set the record with what is needed
                    if attrs.editableRecordPlaceholder
                        $scope.$eval("#{attrs.editableRecordPlaceholder}") $scope.$$placeholder
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
                            if attrs.onDelete
                                $scope.$eval(attrs.onDelete)(record)
                            #and with an item removed, the list itself is updated
                            $scope.$digest()
                            $scope.$emit 'updaterecord', list
                        else
                            for item in list
                                prune record, item.subitems or []
                    prune record, ngModel.$modelValue
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
                        $rootScope.sorting = true
                        element.addClass 'sorting'
                        $item.addClass 'sorted'
                        _super $item, container
                    onDrop: ($item, targetContainer, _super) ->
                        $rootScope.sorting = false
                        element.removeClass 'sorting'
                        $item.removeClass 'sorted'
                        new_order = []
                        serialized = element.sortable('serialize')
                        recurse = (buffer, source) ->
                            for o in (source or [])
                                if o.record
                                    buffer.push o.record
                                    if attrs.editableListNested?
                                        #new blank buffer, as this may be empty now
                                        o.record.subitems = []
                                        recurse o.record.subitems, o.children
                        recurse new_order, serialized
                        if attrs.editableListReorder
                            $scope.$apply ->
                                $scope.$emit attrs.editableListReorder, new_order
                        _super $item, targetContainer
                    isValidTarget: (item, container, totalSlots, toSlot) ->
                        #if there is a placeholder we can't drag to the last record
                        #as that makes an odd visual layout. this has the effect
                        #of keeping the placeholder last
                        if element.find('.editableRecordPlaceholder').length
                            (toSlot + 1) < totalSlots
                        else
                            true
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
                    if model?.length is 1
                        $timeout ->
                            $scope.$broadcast 'selectedrecord', model[0]
                #this is a relay event from contained records up to this list
                #tell all the child records that there has been a selection
                #so they can hide themselves, unbind, etc.
                $scope.$on 'selectrecord', (event, record) ->
                    event.stopPropagation()
                    $scope.selectedrecord = record
                    $scope.$broadcast 'selectedrecord', record
                #when there is a new record, add it into the current view model
                #this is in addition to any update that fires to send things
                #back to the underlying database
                $scope.$on 'newrecord', (event, record) ->
                    event.stopPropagation()
                    list = ngModel.$modelValue
                    $scope.selectedrecord = record
                    list.push record
                    #new records should be selected right away, you are working
                    #on it right now after all...
                    $scope.$broadcast 'selectedrecord', record
                    #buble up an update, a new is an update too and this is
                    #needed to allow parent records to know of a child update
                    $scope.$emit 'updaterecord', record
                #When there is a deleted record, remove it from the local view
                #and fire the callback
                $scope.$on 'deleterecord', (event, record) ->
                    event.stopPropagation()
                    if attrs.onDelete
                        $scope.$eval(attrs.onDelete)(record)
                    #and with an item removed, the list itself is updated
                    $scope.$emit 'updaterecord', ngModel.$modelValue
                #and handle events coming up from nested editable records
                #and fire the controller callback if specified
                $scope.$on 'updaterecord', (event, record) ->
                    #on purpose, only trapping the event if we have a callback
                    #this will let parent records update if nested lists
                    #are modified
                    if attrs.onUpdate
                        event.stopPropagation()
                        $scope.$eval("#{attrs.onUpdate}")(record)
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
