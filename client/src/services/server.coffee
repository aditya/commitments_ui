###
All about talking to the server, sending and receiving messages over socket.io
that are then dispatched to appropriate services to maintain state.
###
define ['angular',
    'socketio',
    'lodash',
    'cs!./root',
    'cs!./user',
    'cs!./sampledata',
    ], (angular, socketio, _, root) ->
        root.factory 'Server', ($rootScope, $timeout, SampleData, User, Database) ->
            #socket io messages aren't in the angular scope, so here is a
            #helper to post a message into angular
            broadcast = (name, message...) ->
                #move into the angular context
                $rootScope.$apply ->
                    $rootScope.$broadcast name, message...
            #there is really just the one socket
            socket = null
            #goodbye cruel server
            disconnect = ->
                if socket
                    try
                        socket.disconnect()
                    catch ex
                        console.log ex
                socket = null
            #connect to the server, with an optional 'join' mode
            connect = (authtoken, join) ->
                #clean up before we start
                disconnect()
                #building up a connection string, different format depending on
                #if the user is trying to join or not
                if join
                    connection_string = "#{User.preferences.server}?authtoken=join:#{encodeURIComponent(authtoken)}"
                else
                    connection_string = "#{User.preferences.server}?authtoken=#{encodeURIComponent(authtoken)}"
                #here we go, a whole new socket starts up
                socket = socketio.connect connection_string,
                    'force new connection': true
                #this is a successful login message
                socket.on 'hello', (email) ->
                    #let everything know
                    broadcast 'loginsuccess',
                        authtoken: authtoken
                        email: email
                    #now that we are logged in, go and get some tasks
                    socket.emit 'exec',
                        command: 'commitments'
                        args: ['list', 'tasks', email]
                        , (items) ->
                            broadcast 'itemsfromserver', items
                            #looking for new tasks...
                            socket.emit 'exec',
                                command: 'commitments'
                                args: ['about', 'user', email]
                                , (about) ->
                                    socket.itemPath = about.directory
                                    socket.emit 'watch', about
                    #...and notifications
                    socket.emit 'exec',
                        command: 'notify'
                        args: ['about', 'user']
                        , (about) ->
                            console.log 'watch', about
                            socket.notifyPath = about.directory
                            socket.emit 'watch', about
                #
                socket.on 'error', ->
                    console.log 'socketerror', arguments
                    if join
                        #nothing to do, login just fails on a join request
                        #as you aren't really a user yet
                        disconnect()
                    else if "#{arguments[0]}".indexOf('unauthorized') >= 0
                        #this appears to be the message coming back from
                        #socket.io on an auth failure
                        broadcast 'loginfailure'
                        disconnect()
                #
                socket.on 'reconnect', ->
                    broadcast 'reconnect'
                #
                socket.on 'addFile', (item) ->
                    if item.filename.indexOf(socket.itemPath) is 0
                        broadcast 'itemfromserver', item.filename, item.data
                    else
                        broadcast 'filefromserver', item.filename, item.data
                #
                socket.on 'changeFile', (item) ->
                    if item.filename.indexOf(socket.itemPath) is 0
                        broadcast 'itemfromserver', item.filename, item.data
                    else
                        broadcast 'filefromserver', item.filename, item.data
                #
                socket.on 'unlinkFile', (item) ->
                    if item.filename.indexOf(socket.itemPath) is 0
                        broadcast 'deleteitemfromserver', item.filename, item.data
                    else
                        broadcast 'deletefilefromserver', item.filename, item.data
            #
            $rootScope.$on 'updateitem', (event, item) ->
                console.log 'server'
                socket.emit 'exec',
                    command: 'commitments'
                    args: ['update', 'task']
                    stdin: item
            #
            $rootScope.$on 'deleteitem', (event, item) ->
                socket.emit 'exec',
                    command: 'commitments'
                    args: ['delete', 'task']
                    stdin: item
            #
            $rootScope.$on 'archiveitem', (event, item) ->
                socket.emit 'exec',
                    command: 'commitments'
                    args: ['archive', 'task']
                    stdin: item
            #
            $rootScope.$on 'filefromserver', _.debounce( ->
                    socket.emit 'exec',
                        command: 'notify'
                        args: ['receive']
                        , (messages) ->
                            for message in messages
                                broadcast 'notification', message
                , 500)
            #
            $rootScope.$on 'useritems', (event, user, callback) ->
                socket.emit 'exec',
                    command: 'commitments'
                    args: ['list', 'tasks', user]
                    , (items) ->
                        callback items
            #tell the server about a new sort order
            $rootScope.$on 'taskssorted', (event, user, tasks) ->
                socket.emit 'exec',
                    command: 'commitments'
                    args: ['rank', 'tasks', user].concat _.map(tasks, (x) -> x.id)
            #**used for local testing**
            window.sampleData = ->
                window.FAKE_SERVER = false
                SampleData()
            window.fakeServer = ->
                window.FAKE_SERVER = !window.FAKE_SERVER
            server =
                tryToBeLoggedIn: ->
                    #check for a running session, this is a quick check to see
                    #if we are logged in. ultimately, if this variable is faked
                    #or poked, there still isn't a server session, so it is
                    #a bit tamper resistant
                    if socket
                        return
                    else if User.persistentIdentity()?.authtoken
                        server.login User.persistentIdentity().authtoken
                join: (email) ->
                    connect email, true
                login: (authtoken) ->
                    connect authtoken
                    $rootScope.$broadcast 'login'
                logout: ->
                    disconnect()
                    $rootScope.$broadcast 'logout'
