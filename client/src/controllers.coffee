define ['angular',
    'lodash',
    'store',
    'cs!./services',
    'text!src/views/tasks.html',
    'text!src/views/trash.html',
    'text!src/views/splash.html',
    'text!src/views/navbar.html',
    'text!src/views/taskhelp.html',
    'text!src/views/taskaccept.html',
    'text!src/views/discussion.html',
    'text!src/views/discussionhelp.html',
    'cs!./editable',
    'cs!./readonly'], (angular, _, store, services, task_template, trash_template, splash_template, navbar_template, taskhelp_template, taskaccept_template, discussion_template, discussionhelp_template) ->
    module = angular.module('Root', ['RootServices', 'editable', 'readonly'])
        .run(['$templateCache', ($templateCache) ->
            console.log 'here we go'
            $templateCache.put 'src/views/navbar.html', navbar_template
            $templateCache.put 'src/views/taskhelp.html', taskhelp_template
            $templateCache.put 'src/views/taskaccept.html', taskaccept_template
            $templateCache.put 'src/views/discussion.html', discussion_template
            $templateCache.put 'src/views/discussionhelp.html', discussionhelp_template
        ])
        .config ($routeProvider) ->
            $routeProvider.
                when(
                    '/todo',
                    template: task_template
                    controller: 'Tasks'
                )
                .when(
                    '/done',
                    template: task_template
                    controller: 'Tasks'
                )
                .when(
                    '/tag',
                    template: task_template
                    controller: 'Tasks'
                )
                .when(
                    '/task/:taskid',
                    template: task_template
                    controller: 'Tasks'
                )
                .when(
                    '/task/:taskid/:commentid',
                    template: task_template
                    controller: 'Tasks'
                )
                .when(
                    '/trash',
                    templateUrl: 'src/views/trash.html'
                    template: trash_template
                )
                .when(
                    '/users',
                    templateUrl: 'src/views/users.html'
                    controller: 'Users'
                )
                .when(
                    '/notifications',
                    templateUrl: 'src/views/notifications.html'
                    controller: 'Notifications'
                )
                .when(
                    '/logout',
                    template: splash_template
                    controller: 'Logout'
                )
                .when(
                    '/login/:authtoken',
                    template: splash_template
                    controller: 'Login'
                )
                .when(
                    '/settings',
                    templateUrl: 'src/views/settings.html'
                    controller: 'Settings'
                )
                .when(
                    '/',
                    template: splash_template
                    controller: 'Splash'
                )
                .otherwise(
                    template: splash_template
                    controller: 'Splash'
                )
        .controller 'Application', ($rootScope, $location, Server, Database, Notifications, StackRank, User, Trash) ->
            #main event handling for being logged in or not
            $rootScope.$on 'loginsuccess', (event, identity) ->
                $rootScope.loggedIn = true
                $rootScope.flash ''
                #default location if nowhere
                console.log $location.path()
                if $location.path() is '/'
                    $location.path '/todo'
            $rootScope.$on 'loginfailure', ->
                $rootScope.loggedIn = false
                $rootScope.flash "Whoops, that's not a valid login link", true
                $location.path '/'
            $rootScope.$on 'logout', ->
                $rootScope.loggedIn = false
                $rootScope.flash "Logging you out"
                $location.path '/'
            #relay this event
            $rootScope.$on 'searchquery', (event, query) ->
                $rootScope.searchQuery = query
            #flash message, just a page with a message when all else fails
            $rootScope.flash = (message, isError) ->
                if message
                    console.log 'FLASH', message
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
                else
                    $rootScope.flashMessage = message
            #bootstrap the application with the core services, put in the scope
            #to allow easy data binding
            $rootScope.notifications = Notifications
            $rootScope.user = User
            $rootScope.trash = Trash
            $rootScope.loggedIn = false
            #here we go
            Server.tryToBeLoggedIn()
        .controller 'Login', ($scope, $routeParams, Server) ->
            Server.login $routeParams.authtoken
            $scope.flash "Logging you in..."
        .controller 'Logout', ($scope, $timeout, $location, Server) ->
            Server.logout()
            $scope.flash "Logging you out..."
        .controller 'Splash', ($scope, $rootScope, $location, Server) ->
            #the actual method to join
            $scope.join = () ->
                Server.join $scope.joinEmail
                $scope.flashing = true
            $scope.joinAgain = () ->
                $scope.joinEmail = ''
                $scope.flashing = false
        .controller 'Navbar', ($rootScope, $scope, $location, $timeout, Notifications) ->
            #event to ask for a new task focus
            $scope.addTask = ->
                if $location.path().slice(-5) is '/done' or $rootScope.lastTaskLocation is '/done'
                    $location.path '/todo'
                else
                    $location.url $rootScope.lastTaskLocation
                $timeout ->
                    $rootScope.$broadcast 'newtask'
        #toolbox has all the boxes, not sure of a better name we can use, what
        #do you call a box of boxes? boxula?
        .controller 'Toolbox', ($scope, $rootScope, $timeout, LocalIndexes, Database) ->
            $scope.boxes = []
            $scope.localIndexes = LocalIndexes
            #here are the various boxes and filters
            rebuild = ->
                console.log 'rebuild boxes'
                $rootScope.boxes = []
                #always have the todo and done boxes
                $rootScope.boxes.push(
                    title: 'Todo'
                    url: '/#/todo'
                ,
                    title: 'Done'
                    url: '/#/done'
                )
                #now build up a 'box' for each tag, not sure why I want to call
                #it a box, just that the tags are drawn on screen in a... box?
                #or maybe that it reminds me of a mailbox
                make = (term) ->
                    $rootScope.boxes.push(
                        title: term
                        tag: term
                        url: "/#/tag?#{encodeURIComponent(term)}"
                    )
                for tagTerm in LocalIndexes.tags()
                    make tagTerm
                #ok, so, I really don't understand why this is required, but
                #without it my boxes list in the navbar is just plain empty
                $scope.boxes = $rootScope.boxes
            #watch the index to see if we should rebuild the facet filtersk
            $scope.$watch 'localIndexes.tagSignature()', ->
                rebuild()
        #nothing nuch going on here
        .controller 'Settings', ($rootScope, $scope) ->
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
        .controller 'Tasks', ($scope, $rootScope, $location, $timeout, $routeParams, Database, LocalIndexes, User) ->
            #this gets it done, selecting items in a box and hooking them to
            #the scope to bind to the view
            selected = $rootScope.selected = {}
            selected.items = Database.items()
            selected.itemCount = ->
                _.reject selected.items, selected.hide
            #this really grabs new data, with a bit of a debounce so we don't
            #bind once for every message on startup
            rebindNow = ->
                keys_now = _.pluck selected.items, 'id'
                items = Database.items()
                keys_maybe = _.pluck items, 'id'
                if _.intersection(keys_now, keys_maybe).length isnt keys_maybe.length
                    console.log 'rebind'
                    selected.items = items
                    $scope.$digest()
            rebind = _.debounce ->
                rebindNow()
            , 300
            #hang on to this
            $rootScope.lastTaskLocation = $location.url()
            #process where we are looking, this is a bit of a sub-router, it is
            #not clear how to do this with the angular base router
            if $location.path().slice(-5) is '/todo'
                selected.title = "Todo"
                selected.allowNew = true
                selected.hide = (x) -> x.done
            else if $location.path().slice(-5) is '/done'
                selected.title = "Done"
                selected.allowNew = false
                selected.hide = (x) -> not x.done
            else if $location.path().slice(0,5) is '/task'
                selected.title = "Task"
                selected.allowNew = false
                selected.hide = (x) -> x?.id isnt $routeParams.taskid
            else if $location.path().slice(-4) is '/tag'
                tag = _.keys($location.search())[0]
                selected.title = tag
                selected.allowNew = true
                selected.hide = (x) -> not (x.tags or {})[tag]
                selected.stamp = (item) ->
                    item.tags = item.tags or {}
                    item.tags[tag] = Date.now()
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
            $scope.archive = (item) ->
                $rootScope.$broadcast 'archiveitemfromlocal', item
            #adding a subitem is just making a nested object
            $scope.subitem = (item) ->
                item.subitems = item.subitems or []
                item.subitems.push {}
            #event handling
            #looking for server updates, in which case we re-select the
            #same box triggering a rebinding
            $scope.$on 'newitemfromserver', ->
                rebind()
            $scope.$on 'deleteitemfromserver', ->
                rebind()
            $scope.$on 'deleteitemfromlocal', ->
                rebind()
            $scope.$on 'itemfromlocal', ->
                rebind()
            $scope.$on 'archiveitemfromlocal', ->
                rebind()
            #search is driven from the navbar, queries then make up a 'fake'
            #box much like the selected tags, but it is instead a list of
            #matching ids
            #this isn't done with navigation, otherwise it would flash focus
            #away from the desktop/input box and be a bit unpleasant
            $scope.$watch 'searchQuery', (query) ->
                #this will save the prior hiding function and swap it out
                #with a search based hiding function
                if query
                    #here is an actual query, the objects are already in memor
                    #so this isn't a copy, just a reference
                    keys = {}
                    for result in LocalIndexes.fullTextSearch(query)
                        keys[result.ref] = result
                    #stash the last hiding function if we haven't already
                    if not $scope.selected.replaceHide
                        $scope.selected.replaceHide = $scope.selected.hide
                    $scope.selected.hide = (x) ->
                        not keys[x.id]
                else
                    if $scope.selected.replaceHide
                        $scope.selected.hide = $scope.selected.replaceHide
                        delete $scope.selected.replaceHide
            #go!
            rebind()
        #notifications, button and dropdown
        .controller 'Notifications', ($scope, $rootScope, Notifications) ->
            $rootScope.iconFor = (notification) ->
                if _.contains notification?.data?.tags, 'comment'
                    return 'icon-comment'
                if _.contains notification?.data?.tags, 'done'
                    return 'icon-check'
                if _.contains notification?.data?.tags, 'undone'
                    return 'icon-check-empty'
                if _.contains notification?.data?.tags, 'accept'
                    return 'icon-ok-sign'
                if _.contains notification?.data?.tags, 'reject'
                    return 'icon-remove-sign'
                if _.contains notification?.data?.tags, 'share'
                    return 'icon-share-alt'
                if _.contains notification?.data?.tags, 'unshare'
                    return 'icon-reply'
                return 'icon-tasks'
            Notifications.deliverMessages()
        #local trash can to allow undelete
        .controller 'Trash', ($rootScope, $scope, $timeout, Trash) ->
            $scope.emptyTrash = ->
                Trash.empty()
            $scope.undelete = (item) ->
                #and undelete is really just the same as an update
                $rootScope.$broadcast 'itemfromlocal', item
        #all the people in all the boxes...
        .controller 'Users', ($scope, $timeout, LocalIndexes) ->
            $scope.localIndexes = LocalIndexes
            $scope.$watch 'localIndexes.linkSignature()', ->
                $scope.users = LocalIndexes.links()
                $scope.items = {}
        #each task, in a controller to limit the digest scope
        .controller 'UserTasks', ($rootScope, $scope, $timeout, StackRank) ->
            #for this user, go and get their items
            $rootScope.$broadcast 'useritems', $scope.user, (items) ->
                #items not yet done, stack rank order
                items = _.filter items, (x) -> not x.done
                items = _.sortBy items, StackRank.comparator
                #top 2, just a preference
                items = items.slice(0, 2)
                $scope.items[$scope.user] = items
                $timeout ->
                    $scope.$digest()
