define ['angular',
    'lodash',
    'store',
    'cs!./services',
    'cs!./services/database',
    'cs!./editable',
    'cs!./readonly'], (angular, _, store, services) ->
    module = angular.module('Root', ['RootServices', 'editable', 'readonly'])
        .config ($routeProvider) ->
            $routeProvider.
                when(
                    '/todo',
                    templateUrl: 'src/views/desktop.html'
                    controller: 'Desktop'
                )
                .when(
                    '/done',
                    templateUrl: 'src/views/desktop.html'
                    controller: 'Desktop'
                )
                .when(
                    '/tag',
                    templateUrl: 'src/views/desktop.html'
                    controller: 'Desktop'
                )
                .when(
                    '/logout',
                    templateUrl: 'src/views/desktop.html'
                    controller: 'Logout'
                )
                .when(
                    '/login/:authtoken',
                    templateUrl: 'src/views/desktop.html'
                    controller: 'Login'
                )
                .when(
                    '/',
                    templateUrl: 'src/views/splash.html'
                    controller: 'Splash'
                )
                ###
                .otherwise(
                    templateUrl: 'src/views/splash.html'
                    controller: 'Splash'
                )
                ###
        .run ($rootScope, $location, Server) ->
            #Theory Question: Should this be a service? There is the routing
            #bit which makes a lot more sense to keep in the controller
            #in this root most controller, listen for login and login failure
            $rootScope.$on 'loginsuccess', (event, identity) ->
                $location.path '/todo'
            $rootScope.$on 'loginfailure', ->
                $rootScope.flash "Whoops, that's not a valid login link", true
            $rootScope.$on 'logout', ->
                $rootScope.flash "Logging you out"
        .controller 'Application', ($rootScope, $location, Database, Notifications, StackRank, User) ->
            #flash message, just a page with a message when all else fails
            $rootScope.flash = (message, isError) ->
                $rootScope.flashMessage = message
                $rootScope.flashType = if isError
                        "alert alert-error"
                    else
                        "alert alert-info"
                if $rootScope.$$phase
                    $location.path '/'
                else
                    $rootScope.$apply ->
                        $location.path '/'
            #bootstrap the application with the core services, put in the scope
            #to allow easy data binding
            $rootScope.database = Database
            $rootScope.notifications = Notifications
            $rootScope.user = User
        .controller 'Login', ($scope, $routeParams, User) ->
            User.login $routeParams.authtoken
            $scope.flash "Logging you in..."
        .controller 'Logout', ($scope, $timeout, $location, User) ->
            User.logout()
        .controller 'Flash', ($scope, $timeout, $location) ->
            #Flash shows a message, and then takes you home to basically
            #simulate restarting/refreshing the app
            $timeout ->
                $location.path '/'
            , 3000
        .controller 'Splash', ($scope, $location, User, Database) ->
            if User.persistentIdentity()
                #If there is a saved login, let's try it
                User.login User.persistentIdentity().authtoken
            else
                #Just show the splash page to anonymous cowards
                $location.path '/'
            #the actual method to join
            $scope.join = () ->
                User.join $scope.joinEmail, true
                $scope.flash "Your join email is on its way to #{$scope.joinEmail}"
                #clear the UI field for user re-use, now that is a phrase...
                $scope.joinEmail = ''
        .controller 'Desktop', ($location, $rootScope, $scope, $routeParams, Database, StackRank, User) ->
            #this gets it done, selecting items in a box and hooking them to
            #the scope to bind to the view
            selectBox = (box) ->
                if box
                    #selecting fires off the filter for a box, then snapshots
                    #those items in stack rank order
                    $scope.selected = box
                    $scope.selected.items = StackRank.sort(
                        (box.filter or -> [])(),
                        (x) -> x.id,
                        box.tag)
            #looking for server updates, in which case we re-select the
            #same box triggering a rebinding
            $scope.$on 'newitemfromserver', (event, item) ->
                console.log 'new item', item.id
                selectBox $scope.selected
            $scope.$on 'deleteitemfromserver', ->
                console.log 'delete item'
                selectBox $scope.selected
            #process where we are looking, this is a bit of a sub-router, it is
            #not clear how to do this with the angular base router
            if not User.email
                #nobody logged in, welcome back to the home page
                $location.path '/'
            else
                if $location.path().slice(-5) is '/todo'
                    selectBox $scope.todoBox
                else if $location.path().slice(-5) is '/done'
                    selectBox $scope.doneBox
                else if $location.path().slice(-4) is '/tag'
                    console.log $scope.boxes
                    selectBox $scope.boxes.tags[_.keys($location.search())[0]]
        #navbar provides all the tools and toggles to control the main user
        #interface, and contains the toolbox and searchbox
        .controller 'Navbar', ($rootScope, $scope, Notifications) ->
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
                if Notifications.unreadCount()
                    #if there are messages, always show
                    $scope.user.preferences.notifications = true
                else
                    #otherwise this is a normal toggle
                    $scope.user.preferences.notifications = not $scope.user.preferences.notifications
                if $scope.user.preferences.notifications
                    Notifications.deliverMessages()
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
        #toolbox has all the boxes, not sure of a better name we can use, what
        #do you call a box of boxes? boxula?
        .controller 'Toolbox', ($scope, $rootScope, LocalIndexes) ->
            $scope.boxes = []
            $scope.lastBox = null
            $scope.localIndexes = LocalIndexes
            $scope.todoCount = (box) ->
                (_.reject (box.filter or -> [])(), (x) -> x.done).length
            #here are the various boxes and filters
            #watch the index to see if we shoudl rebuild the facet filters
            $scope.$watch 'localIndexes.tags()', ->
                console.log 'rebuild boxes'
                $rootScope.boxes = []
                #always have the todo and done boxes
                $rootScope.boxes.push(
                    title: 'Todo'
                    tag: '*todo*'
                    filter: -> $scope.database.items (x) -> not x.done
                    hide: (x) -> x.done
                    allowNew: true
                    url: '/#/todo'
                ,
                    title: 'Done'
                    tag: '*done*'
                    filter: -> $scope.database.items (x) -> x.done
                    hide: (x) -> not x.done
                    allowNew: false
                    url: '/#/done'
                )
                $rootScope.boxes.tags = {}
                #stash these, they may be re-ordered
                $rootScope.todoBox = $rootScope.boxes[0]
                $rootScope.doneBox = $rootScope.boxes[1]
                #dynamic tags from the index, these are current
                tags = {}
                #the filtering methods used to select items under a tag
                byTag = (tagTerm, filter) ->
                    () ->
                        by_tag = {tags: {}}
                        by_tag.tags[tagTerm] = 1
                        $scope.database.itemsByTag(by_tag, filter)
                stampWithTag = (tagTerm) ->
                    (item) ->
                        item.tags = item.tags or {}
                        item.tags[tagTerm] = Date.now()
                #now build up a 'box' for each tag, not sure why I want to call
                #it a box, just that the tags are drawn on screen in a... box?
                #or maybe that it reminds me of a mailbox
                for tagTerm in LocalIndexes.tags()
                    dynamicTag =
                        title: tagTerm
                        tag: tagTerm
                        when: Date.now()
                        allowNew: true
                        hide: -> false
                        filter: byTag(tagTerm)
                        stamp: stampWithTag(tagTerm)
                        url: "/#/tag?#{encodeURIComponent(tagTerm)}"
                    $rootScope.boxes.push dynamicTag
                    $rootScope.boxes.tags[tagTerm] = dynamicTag
                #ok, so, I really don't understand why this is required, but
                #without it my boxes list in the navbar is just plain empty
                $scope.boxes = $rootScope.boxes
            , true
        #nothing nuch going on here
        .controller 'User', ($rootScope, $scope) ->
            null
        #nothing much going on here
        .controller 'Discussion', ($scope) ->
            null
        #accepting and rejecting tasks is simply about stamping it with
        #your user identity, or removing yourself
        .controller 'TaskAccept', ($scope, $timeout) ->
            $scope.accept = (item) ->
                item.links[$scope.user.email] = item.links[$scope.user.email] or Date.now()
                item.accept[$scope.user.email] = Date.now()
                delete item.reject[$scope.user.email]
                $scope.database.update item
            $scope.reject = (item) ->
                item.reject[$scope.user.email] = Date.now()
                delete item.links[$scope.user.email]
                delete item.accept[$scope.user.email]
                $scope.database.update item
        #bulk sharing function, puts all the users on all the items
        .controller 'BulkShare', ($scope) ->
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
        .controller 'Tasks', ($scope, $rootScope, LocalIndexes) ->
            $scope.tags = LocalIndexes.tags
            $scope.links = LocalIndexes.links
            $scope.poke = (item) ->
                console.log 'poking', item
            #placeholders call back to the currently selected box to stamp them
            #as needed to appear in that box
            $scope.placeholderItem = (item) ->
                ($scope.selected.stamp or ->)(item)
            #relay controller binding along to events, it's not convenient to
            #type all this in an ng-click...
            $scope.update = (item) ->
                $rootScope.$broadcast 'itemfromlocal', item
            $scope.delete = (item) ->
                $rootScope.$broadcast 'deleteitemfromlocal', item
        #notifications, button and dropdown
        .controller 'Notifications', ($scope) ->
            $scope.showNotifications = ->
                #receive message and reset the bound scope
                $scope.notifications =
                    $scope.database.notifications.deliverMessages()
