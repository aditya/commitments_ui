define ['md5',
    'markdown',
    'moment',
    'jqueryui',], (md5, markdown, moment) ->
    counter = 0;
    ANIMATION_SPEED = 200
    module = angular.module('editable', [])
        .directive('editableRecord', [() ->
            scope: true
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'editableRecord'
                #fields that are always required
                $scope.$watch attrs.ngModel, (model) ->
                    if not model.id
                        model.id = md5("#{Date.now()}#{counter++}")
                    if not model.who
                        model.who = $scope.user.email
                    if not model.when
                        model.when = Date.now()
                element.on 'click', (event) ->
                    #tell the parent list all about it
                    $scope.$emit 'selectedrecord', ngModel.$modelValue
                $scope.$on 'focus', (event, data) ->
                    #Set a value in scope to then trigger a bind of extended
                    #if this is used in any view, it will now bind
                    if data is ngModel.$modelValue
                        $scope.extended = ngModel.$modelValue
                    else
                        $scope.extended = null
                $scope.$on 'edit', (event, name, value) ->
                    console.log name, value
                    #look for field level edits, in which case this record was
                    #update so send along an event
                    $scope.$emit 'editableRecordUpdate', $scope.$eval(attrs.ngModel)
                    event.stopPropagation()
                #and handle events coming up from nested editable records
                #and fire the controller callback if specified
                $scope.$on 'editableRecordUpdate', (event, record) ->
                    if attrs.onUpdate
                        $scope.$eval("#{attrs.onUpdate}")($scope.$eval(attrs.ngModel))
                        event.stopPropagation()
        ])
        #a required field will trigger an event when the value is set or unset
        #this is used for implicit deletes as well as turning placeholder
        #records into real records
        .directive('requiredFor', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                $scope.$watch attrs.ngModel, (value) ->
                    target = $scope.$eval(attrs.requiredFor)
                    if value
                        $scope.$emit 'editableRecordHasRequired', $scope.$eval(attrs.requiredFor)
                    else
                        $scope.$emit 'editableRecordMissingRequired', $scope.$eval(attrs.requiredFor)
        ])
        #mark a field as editable, this will fire an event when the model value
        #changes allowing parent records to look into individual properies
        .directive('editable', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'editable'
                #make sure there is always a list if we change models
                #with a counter so this does not fire on the initial update
                count = 0
                $scope.$watch attrs.ngModel, (value) ->
                    if count++
                        $scope.$emit 'edit', attrs.ngModel, value
        ])
        #equip a list with drag and drop reordering, used ot stack rank tasks
        .directive('editableListReorder', [() ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                #using jQuery, so this is not all that impressive
                element.sortable
                    cursor: 'move'
                element.css 'cursor', 'move'
                element.on 'sortupdate', ->
                    $scope.stackRank.renumber(
                        element.children('.editableRecord').map((_, x) -> $(x).data 'record'),
                        $scope.user.email,
                        $scope.$eval(attrs.editableListReorder))
        ])
        .directive('editableList', ['$timeout', ($timeout) ->
            scope: true
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                #make sure there is a model
                if not ngModel.$modelValue
                    ngModel.$modelValue = []
                #ability to create a placeholder record
                newPlaceholder = ->
                    if not ngModel.$modelValue.$$placeholder
                        record = {}
                        if attrs.onPlaceholder
                            $scope.$eval("#{attrs.onPlaceholder}")(record)
                        ngModel.$modelValue.$$placeholder = record
                        ngModel.$modelValue.push record
                #make sure there is always a list if we change models
                $scope.$watch attrs.ngModel, ->
                    if not ngModel.$viewValue
                        ngModel.$setViewValue([])
                    #and the initial placeholder
                    if attrs.editableListBlankRecord?
                        newPlaceholder()
                $scope.$on 'selectedrecord', (event, data) ->
                    event.stopPropagation()
                    $scope.$broadcast 'focus', data
                    $scope.$digest()
                #if all the required fields are in place, then make sure
                #we have a proper placeholder record if so configured
                $scope.$on 'editableRecordHasRequired', (event, record) ->
                    if record is ngModel.$modelValue.$$placeholder
                        if attrs.editableListBlankRecord?
                            ngModel.$modelValue.$$placeholder = null
                            newPlaceholder()
                    event.stopPropagation()
                #if we are missing required fields, delete the record
                #unless it is a placeholder
                $scope.$on 'editableRecordMissingRequired', (event, record) ->
                    if record is ngModel.$modelValue.$$placeholder
                        #this record cannot be deleted
                    else
                        if attrs.onDelete
                            $scope.$eval("#{attrs.onDelete}")(record)
                        #update the bound list without going back to the data source
                        list = ngModel.$modelValue
                        foundAt = list.indexOf(record)
                        if foundAt >= 0
                            list.splice(foundAt, 1)
                        $scope.$emit 'editableRecordUpdate', record
                    event.stopPropagation()
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
