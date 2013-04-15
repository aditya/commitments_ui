define ['angular',
    'lodash',
    'cs!src/services',
    'cs!src/editable',
    'cs!src/readonly'], (angular, _) ->
    module = angular.module('Root', ['RootServices', 'editable', 'readonly'])
        .controller 'Desktop', ($scope, Database, StackRank, Authentication) ->
            $scope.stackRank = StackRank()
            $scope.database = Database()
            $scope.user = Authentication.user
            $scope.boxes = []
            $scope.messages =
                info: 'Alerts & Messages'
                count: 0
            $scope.lastBox = null
            $scope.selectBox = (box) ->
                if box
                    #save boxes worth remembering, this lets us revert from
                    #search to the last view
                    if not $scope?.selected?.forgettable
                        $scope.lastBox = $scope.selected
                    #selecting fires off the filter for a box, then snapshots
                    #those items in stack rank order
                    $scope.selected = box
                    $scope.selected.items = $scope.stackRank.sort(
                        (box.filter or -> [])(),
                        $scope.user.email,
                        box.tag)
            $scope.todoCount = (box) ->
                (_.reject (box.filter or -> [])(), (x) -> x.done).length
            $scope.poke = (item) ->
                console.log 'poking', item
            #placeholders call back to the currently selected box to stamp them
            #as needed to appear in that box
            $scope.placeholderItem = (item) ->
                ($scope.selected.stamp or ->)(item)
            #looking for the initial load of data in order to start off the
            #gui with a screen full of todos
            $scope.$on 'initialload', ->
                console.log 'initial load of screen from server'
                $scope.selectBox $scope.todoBox
            #here are the various boxes and filters
            #watch the index to see if we shoudl rebuild the facet filters
            $scope.$watch 'database.tagIndex.revision()', ->
                console.log 'rebuild boxes'
                $scope.boxes = []
                #always have the todo and done boxes
                $scope.boxes.push(
                    title: 'Todo'
                    tag: '*'
                    filter: -> $scope.database.items (x) -> not x.done
                    hide: (x) -> x.done
                ,
                    title: 'Done'
                    tag: '*'
                    filter: -> $scope.database.items (x) -> x.done
                    hide: (x) -> not x.done
                )
                #initial view selection is the TODO box
                $scope.todoBox = $scope.boxes[0]
                if not $scope.selected
                    $scope.selectBox $scope.boxes[0]
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
                        stamp: stampWithTag(tagTerm)
                    #make an object sandwich, overlaying the dynamic functions
                    #but only using the tag term as the base default, prefering
                    #what the user has updated
                    _.extend dynamicTag, dynamicTagMethods
                    $scope.boxes.push dynamicTag
        .controller 'Navbar', ($scope) ->
            #bulk sharing is driven from the navbar
            rebuildAllUsers = (items) ->
                allUsers = {}
                for item in items
                    for user, __ of (item.links or {})
                        allUsers[user] = 1
                if allUsers[$scope.user.email]
                    delete allUsers[$scope.user.email]
                $scope.selected.allUsers = allUsers
            #ui toggle has a bit of data rebuild along with it
            $scope.toggleBulkShare = ->
                $scope.database.preferences.bulkShare = not $scope.database.preferences.bulkShare
                if $scope.database.preferences.bulkShare
                    rebuildAllUsers $scope.selected.items
            #search is driven from the navbar, queries then make up a 'fake'
            #box much like the selected tags, but it is instead a list of
            #matching ids
            $scope.$watch 'searchQuery', (searchQuery) ->
                if searchQuery
                    keys = {}
                    for result in $scope.database.fullTextIndex.search(searchQuery)
                        keys[result.ref] = result
                    searchBox =
                        forgettable: true
                        title: 'Search Results'
                        tag: '*'
                        filter: -> $scope.database.items (x) -> keys[x.id]
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
                $scope.database.update item
            $scope.reject = (item) ->
                item.reject[$scope.user.email] = Date.now()
                delete item.links[$scope.user.email]
                delete item.accept[$scope.user.email]
                $scope.database.update item
        .controller 'BulkShare', ($scope) ->
            #bulk sharing function, puts all the users on all the items
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
