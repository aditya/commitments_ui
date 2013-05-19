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
                    '/task/:taskid',
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
                .otherwise(
                    templateUrl: 'src/views/splash.html'
                    controller: 'Splash'
                )
        .run ($rootScope, $location, Server, User) ->
            #Theory Question: Should this be a service? There is the routing
            #bit which makes a lot more sense to keep in the controller
            #in this root most controller, listen for login and login failure
            $rootScope.$on 'loginsuccess', (event, identity) ->
                $location.path User.lastLocation() or '/todo'
            $rootScope.$on 'loginfailure', ->
                $rootScope.flash "Whoops, that's not a valid login link", true
            $rootScope.$on 'logout', ->
                $rootScope.flash "Logging you out"
            $rootScope.$on 'notloggedin', ->
                if $location.path() isnt '/'
                    $location.path '/'
        .controller 'Application', ($rootScope, $location, Server, Database, Notifications, StackRank, User, Trash) ->
            Server.tryToBeLoggedIn()
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
            $rootScope.notifications = Notifications
            $rootScope.user = User
            $rootScope.trash = Trash
        .controller 'Login', ($scope, $routeParams, Server) ->
            Server.login $routeParams.authtoken
            $scope.flash "Logging you in..."
        .controller 'Logout', ($scope, $timeout, $location, Server) ->
            Server.logout()
        .controller 'Flash', ($scope, $timeout, $location) ->
            #Flash shows a message, and then takes you home to basically
            #simulate restarting/refreshing the app
            $timeout ->
                $location.path '/'
            , 3000
        .controller 'Splash', ($scope, $location, User, Database) ->
            #the actual method to join
            $scope.join = () ->
                Server.join $scope.joinEmail
                $scope.flashing = true
            $scope.joinAgain = () ->
                $scope.joinEmail = ''
                $scope.flashing = false
        .controller 'Desktop', ($location, $rootScope, $scope, $routeParams, $timeout, Database, StackRank, LocalIndexes, User) ->
            #this gets it done, selecting items in a box and hooking them to
            #the scope to bind to the view
            selectBox = (box, bonusFilter) ->
                if box
                    console.log 'box', box.title
                    bonusFilter = bonusFilter or -> true
                    #selecting fires off the filter for a box, then snapshots
                    #those items in stack rank order
                    $scope.selected = box
                    $scope.selected.fetchItems = -> StackRank.sort(
                        _.filter((box.filter or -> [])(), bonusFilter),
                        (x) -> x.id,
                        box.tag)
                    $scope.selected.items = $scope.selected.fetchItems()
                    User.lastLocation $location.path()
                    hideThemAll()
                    $scope.showTasks = true
            hideThemAll = ->
                $scope.showTasks = false
                $scope.showTrash = false
                $scope.showNotifications = false
            #process where we are looking, this is a bit of a sub-router, it is
            #not clear how to do this with the angular base router
            if $location.path().slice(-5) is '/todo'
                selectBox(
                    title: 'Todo'
                    tag: '**todo**'
                    filter: -> Database.items (x) -> not x.done
                    allowNew: true
                )
            else if $location.path().slice(-5) is '/done'
                selectBox(
                    title: 'Done'
                    tag: '**done**'
                    filter: -> Database.items (x) -> x.done
                    allowNew: true
                    stamp: (item) ->
                        item.done = Date.now()
                )
            else if $location.path().slice(0,5) is '/task'
                selectBox(
                    title: 'Task'
                    tag: ''
                    filter: -> [Database.item($routeParams.taskid)]
                    allowNew: false
                    url: "/#/task#{$routeParams.taskid}"
                )
            else if $location.path().slice(-4) is '/tag'
                tag = _.keys($location.search())[0]
                selectBox(
                    title: tag
                    tag: tag
                    filter: ->
                        Database.itemsByTag tag
                    stamp: (item) ->
                        item.tags = item.tags or {}
                        item.tags[tag] = Date.now()
                    allowNew: true
                    url: "/#/tag?#{encodeURIComponent(tag)}"
                )
            #event handling
            #search is driven from the navbar, queries then make up a 'fake'
            #box much like the selected tags, but it is instead a list of
            #matching ids
            #this isn't done with navigation, otherwise it would flash focus
            #away from the desktop/input box and be a bit unpleasant
            $scope.$on 'searchquery', (event, query) ->
                console.log 'query', query
                if query
                    keys = {}
                    for result in LocalIndexes.fullTextSearch(query)
                        keys[result.ref] = result
                    #just change the items
                    $scope.selected.items =
                        Database.items (x) -> keys[x.id]
                else
                    #reset to the selected box
                    selectBox $scope.selected
            $scope.$on "showTrash", ->
                hideThemAll()
                $scope.showTrash = true
            $scope.$on "showNotifications", ->
                hideThemAll()
                $scope.showNotifications = true
            $scope.$on "showTasks", ->
                hideThemAll()
                $scope.showTasks = true
        #navbar provides all the tools and toggles to control the main user
        #interface, and contains the toolbox and searchbox
        .controller 'Navbar', ($rootScope, $scope, $location, Notifications) ->
            $scope.toggleNotifications = ->
                $rootScope.$broadcast "showNotifications"
            $scope.toggleTrash = ->
                $rootScope.$broadcast "showTrash"
            $scope.toggleTasks = ->
                $rootScope.$broadcast "showTasks"
            #event to ask for a new task focus
            $scope.addTask = ->
                $rootScope.$broadcast 'showTasks'
                $rootScope.$broadcast 'newtask'
        #toolbox has all the boxes, not sure of a better name we can use, what
        #do you call a box of boxes? boxula?
        .controller 'Toolbox', ($scope, $rootScope, $timeout, LocalIndexes, Database) ->
            $scope.boxes = []
            $scope.lastBox = null
            $scope.localIndexes = LocalIndexes
            $scope.todoCount = (box) ->
                (_.reject (box.filter or -> [])(), (x) -> x.done).length
            #here are the various boxes and filters
            rebuild = ->
                console.log 'rebuild boxes'
                $rootScope.boxes = []
                #always have the todo and done boxes
                $rootScope.boxes.push(
                    title: 'Todo'
                    url: '/#/todo'
                    count: ->
                        (Database.items (x) -> not x.done).length
                ,
                    title: 'Done'
                    url: '/#/done'
                    count: ->
                        (Database.items (x) -> x.done).length
                )
                #now build up a 'box' for each tag, not sure why I want to call
                #it a box, just that the tags are drawn on screen in a... box?
                #or maybe that it reminds me of a mailbox
                make = (term) ->
                    $rootScope.boxes.push(
                        title: term
                        tag: term
                        url: "/#/tag?#{encodeURIComponent(term)}"
                        count: ->
                            (Database.itemsByTag term).length
                    )
                for tagTerm in LocalIndexes.tags()
                    make tagTerm
                #ok, so, I really don't understand why this is required, but
                #without it my boxes list in the navbar is just plain empty
                $scope.boxes = $rootScope.boxes
            #watch the index to see if we should rebuild the facet filtersk
            $scope.$watch 'localIndexes.signature()', ->
                rebuild()
            $scope.$on 'rebuild', ->
                rebuild()
        #nothing nuch going on here
        .controller 'User', ($rootScope, $scope) ->
            null
        #nothing much going on here
        .controller 'Discussion', ($scope) ->
            null
        #accepting and rejecting tasks is simply about stamping it with
        #your user identity, or removing yourself
        .controller 'TaskAccept', ($scope, $rootScope) ->
            $scope.accept = (item) ->
                item.links[$scope.user.email] = item.links[$scope.user.email] or Date.now()
                item.accept[$scope.user.email] = Date.now()
                delete item.reject[$scope.user.email]
                $rootScope.$broadcast 'itemfromlocal', item
            $scope.reject = (item) ->
                item.reject[$scope.user.email] = Date.now()
                delete item.links[$scope.user.email]
                delete item.accept[$scope.user.email]
                $rootScope.$broadcast 'itemfromlocal', item
        #task list level controller
        .controller 'Tasks', ($scope, $rootScope, LocalIndexes) ->
            $scope.tags = LocalIndexes.tags
            $scope.links = LocalIndexes.links
            $scope.poke = (item) ->
                $rootScope.$broadcast 'pokeitem', item
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
            #event handling
            #looking for server updates, in which case we re-select the
            #same box triggering a rebinding
            rebind = ->
                if $scope.selected
                    $scope.selected.items = $scope.selected.fetchItems()
                $rootScope.$broadcast 'rebuild'
            $scope.$on 'newitemfromserver', (event, item) ->
                rebind()
            $scope.$on 'deleteitemfromserver', ->
                rebind()
            $scope.$on 'deleteitem', ->
                rebind()
            $scope.$on 'itemfromlocal', ->
                rebind()
        #notifications, button and dropdown
        .controller 'Notifications', ($scope, $rootScope) ->
            $rootScope.iconFor = (notification) ->
                if _.contains notification?.data?.tags, 'comment'
                    return 'icon-comment'
                if _.contains notification?.data?.tags, 'done'
                    return 'icon-check'
                if _.contains notification?.data?.tags, 'undone'
                    return 'icon-check-empty'
                if _.contains notification?.data?.tags, 'accept'
                    return 'icon-link'
                if _.contains notification?.data?.tags, 'reject'
                    return 'icon-unlink'
                if _.contains notification?.data?.tags, 'share'
                    return 'icon-share-alt'
                if _.contains notification?.data?.tags, 'unshare'
                    return 'icon-reply'
        #local trash can to allow undelete
        .controller 'Trash', ($rootScope, $scope, $timeout, Trash) ->
            $scope.emptyTrash = ->
                Trash.empty()
            $scope.undelete = (item) ->
                #and undelete is really just the same as an update
                $rootScope.$broadcast 'itemfromlocal', item
