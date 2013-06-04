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
                    $scope.$digest()
                ), (->
                    $scope.hover = false
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
                        $scope.extended = ngModel.$modelValue
                        $scope.focused = true
                    else
                        $scope.focused = false
                #listening for the focus event, in order to bind
                #entended/hidden properties, this is coming 'down' from the
                #parent list
                $scope.$on 'selectedrecord', (event, data) ->
                    #Set a value in scope to then trigger a bind of extended
                    #if this is used in any view, it will now bind, so we have
                    #afforded delayed binding if you hook on to extended as
                    #a property
                    if data is ngModel.$modelValue
                        $scope.extended = ngModel.$modelValue
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
        #equip a list with drag and drop reordering, used ot stack rank tasks
        .directive('editableListReorder', [ ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                id = md5("#{Date.now()}#{counter++}")
                element.sortable
                    group: id
                    handle: attrs.handle or '.handle'
                    nested: attrs.nested?
                    placeholder: '<li class="icon-chevron-right placeholder"/>'
                    onDragStart: ($item, container, _super) ->
                        $scope.sorting = true
                        element.addClass 'sorting'
                        _super $item, container
                    onDrop: ($item, targetContainer, _super) ->
                        $scope.sorting = false
                        element.removeClass 'sorting'
                        new_order = []
                        serialized = element.sortable('serialize')
                        recurse = (buffer, source) ->
                            for o in (source or [])
                                if o.record
                                    buffer.push o.record
                                    if attrs.nested?
                                        #new blank buffer, as this may be empty now
                                        o.record.subitems = []
                                        recurse o.record.subitems, o.children
                        recurse new_order, serialized
                        if attrs.sortUpdate
                            $scope.$eval(attrs.sortUpdate) new_order
                        element.sortable 'disable'
                        _super $item, targetContainer
                #flipping drag on and off allows nested lists with separate
                #sort spaces
                element.sortable 'disable'
                $scope.$on 'handleon', (event) ->
                    element.sortable 'enable'
                    event.stopPropagation()
        ])
        #drag handles give off events to inform draggable lists
        .directive('handle', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.addClass 'handle'
                element.on 'mousedown', (-> $scope.$emit 'handleon'),
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
                    #update the bound list without going back to the data source
                    #so we avoid a re-draw of the entire list
                    list = ngModel.$modelValue
                    foundAt = list.indexOf(record)
                    if foundAt >= 0
                        list.splice(foundAt, 1)
                        if attrs.onDelete
                            $scope.$eval("#{attrs.onDelete}")(record)
                        #and with an item removed, the list itself is updated
                        $scope.$emit 'updaterecord', list
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
