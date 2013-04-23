define ['angular',
    'lodash',
    'cs!src/services',
    'cs!src/editable',
    'cs!src/readonly'], (angular, _) ->
    module = angular.module('Root', ['RootServices', 'editable', 'readonly'])
        .config(['$routeProvider', ($routeProvider) ->
            $routeProvider.
                when '/users/:email',
                    templateUrl: 'src/views/desktop.html'
                    controller: 'Desktop'
        ])
        .controller 'Application', ($rootScope, $location, Database, StackRank, User) ->
            #bootstrap the application with the core services, put in the scope
            #to allow easy data binding
            $rootScope.stackRank = StackRank
            $rootScope.database = Database
            $rootScope.user = User
            $rootScope.hotwire = ->
                if not $rootScope.shownAtAll
                    $location.path '/users/wballard@glgroup.com'
                    $rootScope.shownAtAll = true
        .controller 'Desktop', ($routeParams, $rootScope, $scope, Database, StackRank, User) ->
            $rootScope.shownAtAll = true
            User.email = $routeParams.email
            #root level section of the current 'box' or set of matching tasks
            #this is used from multiple sub controllers, so here it is at root
            $scope.selectBox = (box) ->
                if box
                    #save boxes worth remembering, this lets us revert from
                    #search to the last view
                    if not $scope?.selected?.forgettable
                        if $scope.lastBox isnt $scope.selected
                            $scope.lastBox = $scope.selected
                    #selecting fires off the filter for a box, then snapshots
                    #those items in stack rank order
                    $scope.selected = box
                    $scope.selected.items = $scope.stackRank.sort(
                        (box.filter or -> [])(),
                        $scope.user.email,
                        box.tag)
            #looking for server updates, in which case we re-select the
            #same box triggering a rebinding
            $scope.$on 'serverupdate', (event, action, item) ->
                $scope.selectBox $scope.selected
        .controller 'Navbar', ($rootScope, $scope) ->
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
                $scope.user.preferences.bulkShare = not $scope.user.preferences.bulkShare
                if $scope.user.preferences.bulkShare
                    rebuildAllUsers $scope.selected.items
            $scope.toggleNotifications = ->
                if $scope.database.notifications.unreadCount()
                    #if there are messages, always show
                    $scope.user.preferences.notifications = true
                else
                    #otherwise this is a normal toggle
                    $scope.user.preferences.notifications = not $scope.user.preferences.notifications
                if $scope.user.preferences.notifications
                    $scope.database.notifications.deliverMessages()
            $scope.addTask = ->
                $rootScope.$broadcast 'newtask'
            #search is driven from the navbar, queries then make up a 'fake'
            #box much like the selected tags, but it is instead a list of
            #matching ids
            $scope.$watch 'searchQuery', (searchQuery) ->
                if searchQuery
                    keys = {}
                    for result in $scope.database.fullTextSearch(searchQuery)
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
            $scope.boxes = []
            $scope.lastBox = null
            $scope.todoCount = (box) ->
                (_.reject (box.filter or -> [])(), (x) -> x.done).length
            #here are the various boxes and filters
            #watch the index to see if we shoudl rebuild the facet filters
            $scope.$watch 'database.opCount()', ->
                console.log 'rebuild boxes'
                $scope.boxes = []
                #always have the todo and done boxes
                $scope.boxes.push(
                    title: 'Todo'
                    tag: '*todo*'
                    filter: -> $scope.database.items (x) -> not x.done
                    hide: (x) -> x.done
                    allowNew: true
                ,
                    title: 'Done'
                    tag: '*done*'
                    filter: -> $scope.database.items (x) -> x.done
                    hide: (x) -> not x.done
                )
                #initial view selection is the TODO box
                $scope.todoBox = $scope.boxes[0]
                if not $scope.selected
                    $scope.selectBox $scope.boxes[0]
                #dynamic tags from the index, these are current
                tags = {}
                for tagTerm in $scope.database.tags()
                    byTag = (tagTerm, filter) ->
                        () ->
                            by_tag = {tags: {}}
                            by_tag.tags[tagTerm] = 1
                            $scope.database.itemsByTag(by_tag, filter)
                    stampWithTag = (tagTerm) ->
                        (item) ->
                            item.tags = item.tags or {}
                            item.tags[tagTerm] = Date.now()
                    dynamicTag =
                        title: tagTerm
                        tag: tagTerm
                        when: Date.now()
                        allowNew: true
                    dynamicTagMethods =
                        hide: -> false
                        filter: byTag(tagTerm)
                        stamp: stampWithTag(tagTerm)
                    #make an object sandwich, overlaying the dynamic functions
                    #but only using the tag term as the base default, prefering
                    #what the user has updated
                    _.extend dynamicTag, dynamicTagMethods
                    $scope.boxes.push dynamicTag
        #control the current user/login/logout state
        .controller 'User', ($rootScope, $scope) ->
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
                    $scope.database.update item
        #task list level controller
        .controller 'Tasks', ($scope) ->
            $scope.poke = (item) ->
                console.log 'poking', item
            #placeholders call back to the currently selected box to stamp them
            #as needed to appear in that box
            $scope.placeholderItem = (item) ->
                ($scope.selected.stamp or ->)(item)
        #notifications, button and dropdown
        .controller 'Notifications', ($scope) ->
            $scope.showNotifications = ->
                #receive message and reset the bound scope
                $scope.notifications =
                    $scope.database.notifications.deliverMessages()
