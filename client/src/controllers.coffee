define [
    'jquery',
    'md5',
    'angular',
    'lodash',
    'store',
    'cs!./services',
    'text!src/views/tasks.html',
    'text!src/views/trash.html',
    'text!src/views/splash.html',
    'text!src/views/navbar.html',
    'text!src/views/taskhelp.html',
    'text!src/views/discussion.html',
    'text!src/views/users.html',
    'text!src/views/notifications.html',
    'text!src/views/user.html',
    'cs!./editable',
    'cs!./readonly'], ($, md5, angular, _, store, services, task_template, trash_template, splash_template, navbar_template, taskhelp_template, discussion_template, users_template, notifications_template, user_template) ->
    module = angular.module('Root', ['RootServices', 'editable', 'readonly'])
        .run(['$templateCache', ($templateCache) ->
            console.log 'here we go'
            $templateCache.put 'src/views/navbar.html', navbar_template
            $templateCache.put 'src/views/taskhelp.html', taskhelp_template
            $templateCache.put 'src/views/discussion.html', discussion_template
            $templateCache.put 'src/views/users.html', users_template
            $templateCache.put 'src/views/notifications.html', notifications_template
            $templateCache.put 'src/views/user.html', user_template
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
                    '/untagged',
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
                    '/tasks',
                    template: task_template
                    controller: 'Tasks'
                )
                .when(
                    '/task/:taskid/:commentid',
                    template: task_template
                    controller: 'Tasks'
                )
                .when(
                    '/users/:email',
                    template: user_template,
                    controller: 'User'
                )
                .when(
                    '/archive',
                    template: task_template
                    controller: 'Archive'
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
        .run ($rootScope) ->
            $rootScope.debug = true
            window.debug = ->
                $rootScope.debug = true
                $rootScope.$digest()
        #Root application controller, deals with login and error messages
        .controller 'Application', ($rootScope, $location, Server, Database, Notifications, User, Trash) ->
            #preloaded to avoid
            $rootScope.selected = {}
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
            $rootScope.database = Database
            $rootScope.loggedIn = false
            #here we go
            Server.tryToBeLoggedIn()
        #Go here to log in, this is used by login token links
        .controller 'Login', ($scope, $routeParams, Server) ->
            Server.login $routeParams.authtoken
            $scope.flash "Logging you in..."
        #Go here to log out
        .controller 'Logout', ($scope, $timeout, $location, Server) ->
            Server.logout()
            $scope.flash "Logging you out..."
        #The splash screen shows when the app starts and you aren't logged in
        .controller 'Splash', ($scope, $rootScope, $location, Server) ->
            #the actual method to join
            $scope.join = () ->
                Server.join $scope.email
                $scope.flashing = true
            $scope.joinAgain = () ->
                $scope.joinEmail = ''
                $scope.flashing = false
        #Top level navigation bar, this is where to hook up hotkeys
        .controller 'Navbar', ($rootScope, $scope, $location, $timeout, Notifications) ->
            #event to ask for a new task focus
            $scope.$on 'addtask', (event) ->
                console.log 'adddddd', event
                if $location.path().slice(-5) is '/done' or $rootScope.lastTaskLocation is '/done'
                    $location.path '/todo'
                else
                    $location.url $rootScope.lastTaskLocation
                $timeout ->
                    $rootScope.$broadcast 'newtaskplaceholder'
            $scope.$on 'searchquery', (event, query) ->
                #on a query, navigate to the new search parameter
                if query
                    $location.url "/tasks?#{encodeURIComponent(query)}"
                    $location.replace() if _.keys($location.search()).length
        #toolbox has all the boxes, not sure of a better name we can use, what
        #do you call a box of boxes? boxula? Each _box_ is a stored filter, either
        #on a tag or a pre-defined set of tasks
        .controller 'Toolbox', ($scope, $rootScope, $timeout, LocalIndexes, Database) ->
            $scope.boxes = []
            $scope.tagUrl = (tag) ->
                "/#/tag?#{encodeURIComponent(tag)}"
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
                ,
                    title: 'Untagged'
                    url: '/#/untagged'
                ,
                    title: 'divider'
                    url: '/#/todo'
                )
                #now build up a 'box' for each tag, not sure why I want to call
                #it a box, just that the tags are drawn on screen in a... box?
                #or maybe that it reminds me of a mailbox
                make = (term) ->
                    $rootScope.boxes.push(
                        title: term
                        tag: term
                    )
                for tagTerm in LocalIndexes.tags()
                    if LocalIndexes.tagCount tagTerm
                        make tagTerm
                #ok, so, I really don't understand why this is required, but
                #without it my boxes list in the navbar is just plain empty
                $scope.boxes = $rootScope.boxes
            #watch the index to see if we should rebuild the facet filtersk
            $scope.$watch LocalIndexes.tagSignature, ->
                rebuild()
        #nothing nuch going on here
        .controller 'Settings', ($rootScope, $scope) ->
            null
        #nothing much going on here
        .controller 'Discussion', ($scope) ->
            null
        #archive list controller
        .controller 'Archive', ($scope, $rootScope, $location, $timeout, $routeParams, Database, User, LocalIndexes, Server) ->
            console.log 'going to the archive'
            $rootScope.selected =
                title: 'Archive'
                allowNew: false
                hide: -> false
            $scope.readonly = true
            $scope.items = Database.archive()
            $scope.hide = -> false
            $scope.hideAcceptReject = -> true
            $scope.hidePokeStatus = -> true
            $scope.hideDelete = -> true
            $scope.hideArchive = -> true
        #task list level controller
        .controller 'Tasks', ($scope, $rootScope, $location, $timeout, $routeParams, Database, User, LocalIndexes) ->
            console.log 'getting items for current user'
            #this gets it done, selecting items in a box and hooking them to
            #the scope to bind to the view
            $scope.items = Database.items()
            selected = $rootScope.selected = {}
            #hang on to this
            $rootScope.lastTaskLocation = $location.url()
            #process where we are looking, this is a bit of a sub-router, it is
            #not clear how to do this with the angular base router
            if $location.path().slice(-5) is '/todo'
                selected.title = "Todo"
                selected.allowNew = true
                selected.hide = (x) -> x.done
            else if $location.path().slice(-6) is '/tasks'
                selected.title = "All"
                selected.allowNew = true
                selected.hide = -> false
                #search filtering
                buildSearchHide = (query) ->
                    #here is an actual query, the objects are already in memory
                    #so this isn't a copy, just a reference
                    if query
                        keys = {}
                        for result in LocalIndexes.fullTextSearch(query)
                            keys[result.ref] = result
                        (task) ->
                            not keys[task.id]
                    else
                        -> false
                #search if we need to
                #redraw forced here, since we had a reload
                $scope.$on 'databaserebuild', ->
                    $scope.items = Database.items()
                    selected.searchHide = buildSearchHide($scope.searchQuery)
                #all set up with search support functions, go ahead and search
                if _.keys($location.search()).length
                    $scope.searchQuery = _.keys($location.search())[0]
                    selected.searchHide = buildSearchHide($scope.searchQuery)
                    selected.title = "Search"
                    $scope.$on 'deselect', ->
                        $location.url '/todo'
                        $location.replace()
            else if $location.path().slice(-5) is '/done'
                selected.title = "Done"
                selected.allowNew = false
                selected.hide = (x) -> (not x.done) or x.archived
            else if $location.path().slice(-9) is '/untagged'
                selected.title = "Untagged"
                selected.allowNew = true
                selected.hide = (x) -> x.done or _.keys(x.tags).length
            else if $location.path().slice(0,5) is '/task'
                selected.title = "Task"
                selected.allowNew = false
                selected.hide = (x) -> x?.id isnt $routeParams.taskid
            else if $location.path().slice(-4) is '/tag'
                tag = _.keys($location.search())[0]
                selected.title = tag
                selected.allowNew = true
                selected.hide = (x) -> (not (x.tags or {})[tag]) or x.archived or x.done
                selected.stamp = (item) ->
                    console.log 'stamping', tag
                    item.tags = item.tags or {}
                    item.tags[tag] = Date.now()
                    console.log item
            #sort event from a sort callback
            $scope.tasksSorted = (tasks) ->
                $scope.$emit 'taskssorted', User.email, tasks
            #visibiliy for tasks accept/reject/poke
            $scope.hide = (task) ->
                selected.hide(task) or (selected.searchHide or -> false)(task)
            $scope.hideAcceptReject = (task) ->
                (not $scope.debug) and
                    (task.who is User.email or task.accept[User.email])
            $scope.hidePokeStatus = (task) ->
                (not $scope.debug) and
                    (not task.poke or task.poke[User.email])
            #visibility control for archive and delete
            $scope.hideDelete = (task) ->
                task.done or $scope.readonly
            $scope.hideArchive = (task) ->
                (not task.done) or $scope.readonly
        #Show a tasklist, provided data has been installed into .selected
        #by a higher level scope.
        .controller 'TaskList', ($scope, $rootScope, $timeout, LocalIndexes, Task) ->
            #filtered item count, this is used to control the display of items
            #or a message if there is nothing
            $rootScope.selected.itemCount = ->
                _.reject $scope.items, $rootScope.selected.hide
            #all the links and tags, used to make the autocomplete
            $scope.tags = -> LocalIndexes.tags()
            $scope.links = -> LocalIndexes.links()
            #url rendering, allows navigation from within tags
            $scope.tagUrl = (tag) ->
                "/#/tag?#{encodeURIComponent(tag)}"
            $scope.userUrl = (tag) ->
                "/#/users/#{encodeURIComponent(tag)}"
            #dealing with creating new tasks is a task list level control action
            #placeholders call back to the currently selected box to stamp them
            #as needed to appear in the current filter box, as well as the
            #actual update event
            $scope.$on 'newtask', (event, task) ->
                console.log 'new', task, $scope.selected.stamp
                ($scope.selected.stamp or ->)(task)
                Task.newtask task
        #each individual task
        .controller 'Task', ($scope, $timeout, User, Task) ->
            #relay events to the task service, but in the local scope
            #to allow digest and redraw
            handle = (event_name, action) ->
                $scope.$on event_name, (event, task) ->
                    action task
                    followon = ->
                        $scope.$digest()
                        if bonus_actions[event_name]
                            $timeout ->
                                bonus_actions[event_name] task
                    if $scope.$$phase
                        $timeout followon
                    else
                        do followon
            #register them all, this way you can just add methods on to Task
            #that are new event handlers
            for event_name, action of Task
                handle event_name, action
            #extra callbacks for the UI
            bonus_actions =
                subtask: (task) ->
                    $timeout ->
                        $scope.$broadcast _.last(task.subitems).id
            #callback to get a status display
            $scope.pokestatus = (email) ->
                poke = $scope.item.poke or {}
                if $scope.item.done
                    $ "<span/>"
                else if _.keys(poke).length
                    if poke[email] is 'notstarted'
                        $ "<span class='icon-frown'/>"
                    else if poke[email] is 'inprogress'
                        $ "<span class='icon-smile'/>"
                    else if poke[email] is 'blocked'
                        $ "<span class='icon-exclamation'/>"
                    else if poke[email] is 'done'
                        $ "<span class='icon-check'/>"
                    else if poke[email] is 'poker'
                        $ "<span class='icon-hand-right'/>"
                    else
                        $ "<span class='icon-question'/>"
            #dynamic inclusion, this is a performance trick to have less going
            #on inside angular js except when it would be visible on screen
            $scope.extendedTemplate = ->
                if $scope.sorting
                    #do not expand while sorting, it is disturbing
                    ''
                else if $scope.focused or $scope.debug
                    'taskextended.html'
                else
                    ''
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
                if _.contains notification?.data?.tags, 'poke'
                    return 'icon-hand-right'
                return 'icon-tasks'
            Notifications.deliverMessages()
        #local trash can to allow undelete
        .controller 'Trash', ($rootScope, $scope, $timeout, Trash) ->
            $scope.trash = Trash
            $rootScope.selected =
                title: 'Trash'
        #all the people in all the boxes...
        .controller 'Users', ($scope, $timeout, LocalIndexes) ->
            $scope.$watch LocalIndexes.linkSignature, ->
                $scope.users = LocalIndexes.links()
                $scope.items = {}
        #Tasks for each user, setting up a scope to query out their current
        #task list
        .controller 'UserTasks', ($rootScope, $scope, $timeout) ->
            #for this user, go and get their items
            $rootScope.$broadcast 'useritems', $scope.user, (items) ->
                #items not yet done
                items = _.filter items, (x) -> not x.done
                #top 2, just a preference
                items = items.slice(0, 2)
                $scope.items[$scope.user] = items
                $timeout ->
                    $scope.$digest()
        #All about a single user
        .controller 'User', ($rootScope, $scope, $routeParams, $timeout, $location, User) ->
            if $routeParams.email is User.email
                console.log 'you clicked yourself'
                $location.path "/todo"
            else
                $scope.from = $routeParams.email
                $scope.tasksSorted = (tasks) ->
                    $scope.$emit 'taskssorted', $scope.from, tasks
                $scope.items = []
                $scope.hideAcceptReject = -> true
                $scope.hidePokeStatus = -> true
                $scope.hideDelete = -> true
                $scope.hideArchive = -> true
                $scope.hide = (x) -> x.done
                #for this user, go and get their items
                $rootScope.$broadcast 'useritems', $scope.from, (items) ->
                    console.log $scope.from, items
                    $scope.items = items
                    $rootScope.selected =
                        iconfrom: 'gravatar'
                        itemCount: -> items.length
                        title: $scope.from
                        allowNew: true
                        stamp: (item) ->
                            #make sure this is linked to the target user, we are in
                            #their list after all
                            item.links = item.links or {}
                            item.links[$scope.from] = Date.now()
                    $timeout ->
                        $scope.$digest()
