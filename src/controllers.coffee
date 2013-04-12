define ['angular',
    'lodash',
    'lunr'
    'cs!src/services',
    'cs!src/editable',
    'cs!src/readonly'], (angular, _, lunr) ->
    module = angular.module('Root', ['RootServices', 'editable', 'readonly'])
        .controller 'Desktop', ($scope, Database, StackRank, Authentication, Preferences, Tags) ->
            $scope.stackRank = StackRank()
            $scope.database = Database()
            $scope.user = Authentication.user
            $scope.tags = Tags
            $scope.preferences = Preferences
            $scope.boxes = []
            $scope.messages =
                info: 'Alerts & Messages'
                count: 0
            $scope.lastBox = null
            $scope.selectBox = (box) ->
                if box
                    #save boxes worth remembering
                    if not $scope?.selected?.forgettable
                        $scope.lastBox = $scope.selected
                    $scope.selected = box
                    $scope.selected.items = $scope.stackRank.sort(
                        (box.filter or -> [])(),
                        $scope.user.email,
                        box.tag)
            $scope.poke = (item) ->
                console.log 'poking', item
            $scope.newItem = (item) ->
                $scope.database.add item
                $scope.lastUpdatedItem = item
            $scope.updateItem = (item) ->
                $scope.database.update item
                $scope.lastUpdatedItem = item
            $scope.placeholderItem = (item) ->
                ($scope.selected.stamp or ->)(item)
            $scope.deleteItem  = (item) ->
                $scope.database.delete item
                $scope.lastDeletedItem = item
            #here are the various boxes and filters
            #watch the index to see if we shoudl rebuild the facet filters
            $scope.$watch 'database.tagIndex.revision()', ->
                $scope.boxes = []
                #always have the todo and done boxes
                $scope.boxes.push(
                    title: 'Todo'
                    tag: '*'
                    filter: -> _.reject($scope.database.items, (x) -> x.done)
                    todoCount: -> _.reject($scope.database.items, (x) -> x.done)
                    hide: (x) -> x.done
                ,
                    title: 'Done'
                    tag: '*'
                    filter: -> _.filter($scope.database.items, (x) -> x.done)
                    todoCount: -> []
                    hide: (x) -> not x.done
                )
                #initial view selection is the TODO box
                if not $scope.selected
                    $scope.selectBox $scope.boxes[0]
                #tags currently used in all tasks
                displayTags = {}
                for tag in $scope.tags
                    displayTags[tag.tag] = tag
                #dynamic tags from the index, these are current
                tags = {}
                for tagTerm in $scope.database.tagIndex.terms()
                    byTag = (tagTerm, filter) ->
                        () ->
                            by_tag = {tags: {}}
                            by_tag.tags[tagTerm] = 1
                            $scope.database.tagIndex.search(by_tag, filter)
                    stampWithTag = (tagTerm) ->
                        (item) ->
                            item.tags = item.tags or {}
                            item.tags[tagTerm] = Date.now()
                    dynamicTag =
                        title: tagTerm
                        tag: tagTerm
                        when: Date.now()
                    dynamicTagMethods =
                        hide: -> false
                        filter: byTag(tagTerm)
                        todoCount: byTag(tagTerm, (x) -> not x.done)
                        stamp: stampWithTag(tagTerm)
                    #make an object sandwich, overlaying the dynamic functions
                    #but only using the tag term as the base default, prefering
                    #what the user has updated
                    _.extend dynamicTag, displayTags[tagTerm] or {}, dynamicTagMethods
                    $scope.boxes.push dynamicTag
        .controller 'Navbar', ($scope) ->
            #The navbar is in charge or the full text index
            fullTextIndex = null
            addToIndex = (item) ->
                fullTextIndex.update
                    id: item.id or ''
                    what: item.what or ''
                    who: _.keys(item.links).join ' '
                    tags: (_.keys(item.tags).join ' ') or ''
                    comments: (_.map(
                        item?.discussion?.comments,
                        (x) -> x.what).join ' ') or ''
            #when the database changes, rebuild a new index
            $scope.$watch 'database', (database) ->
                fullTextIndex = lunr ->
                    @field 'what', 8
                    @field 'who', 4
                    @field 'tags', 2
                    @field 'comments', 1
                    @ref 'id'
                for item in database.items
                    addToIndex item
            #peek at the model to see when it it time to add or remove an item
            $scope.$watch 'lastUpdatedItem', (item) ->
                if item
                    addToIndex item
            , true
            $scope.$watch 'lastDeletedItem', (item) ->
                if item
                    fullTextIndex.remove
                        id: item.id
            , true
            #and search
            $scope.$watch 'searchQuery', (searchQuery) ->
                if searchQuery
                    keys = {}
                    for result in fullTextIndex.search(searchQuery)
                        keys[result.ref] = result
                    searchBox =
                        forgettable: true
                        title: 'Search Results'
                        tag: '*'
                        filter: -> _.filter($scope.database.items, (x) -> keys[x.id])
                        todoCount: -> _.reject($scope.boxes.search.filter(), (x) -> x.done)
                    $scope.selectBox searchBox
                else
                    $scope.selectBox $scope.lastBox
        .controller 'Toolbox', ($scope, $rootScope) ->
            null
        .controller 'Discussion', ($scope) ->
            null
        #accepting and rejecting tasks is simply about stamping it with
        #your user identity, or removing yourself
        .controller 'TaskAccept', ($scope, $timeout) ->
            $scope.accept = (item) ->
                item.accept[$scope.user.email] = Date.now()
                delete item.reject[$scope.user.email]
            $scope.reject = (item) ->
                item.reject[$scope.user.email] = Date.now()
                delete item.links[$scope.user.email]
                delete item.accept[$scope.user.email]
        .controller 'BulkShare', ($scope) ->
            rebuildAllUsers = (items) ->
                allUsers = {}
                for item in items
                    for user, __ of (item.links or {})
                        allUsers[user] = 1
                if allUsers[$scope.user.email]
                    delete allUsers[$scope.user.email]
                $scope.selected.allUsers = allUsers
            $scope.bulkShare = (all) ->
                for item in $scope.selected.items
                    if item?.links?[$scope.user.email]
                        item.links = {}
                        item.links[$scope.user.email] = Date.now()
                    else
                        #big blank set
                        item.links = {}
                    for user in _.keys(all)
                        item.links[user] = Date.now()
            $scope.$watch 'selected.items', (items) ->
                rebuildAllUsers(items)
            $scope.$watch 'lastUpdatedItem', (item) ->
                rebuildAllUsers($scope.selected.items)
            , true
        .config ->
            null
        .run ->
            console.log 'starting application'
