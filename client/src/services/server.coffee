###
All about talking to the server, sending and receiving messages over socket.io
that are then dispatched to appropriate services to maintain state.

The server is completely event driven, exposing no methods. Let's keep it that
way.
###
define ['angular',
    'socketio',
    'lodash',
    'cs!./root',
    'cs!./user',
    'cs!./sampledata',
    ], (angular, socketio, _, root) ->
        root.factory 'Server', ($rootScope, $timeout, SampleData) ->
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
                disconnect()
                #building up a connection string, different format depending on
                #if the user is trying to join or not
                if join
                    connection_string = "#{$rootScope.user.preferences.server}?authtoken=join:#{encodeURIComponent(authtoken)}"
                else
                    connection_string = "#{$rootScope.user.preferences.server}?authtoken=#{encodeURIComponent(authtoken)}"
                console.log 'connecting', connection_string
                #here we go, a whole new socket starts up
                socket = socketio.connect connection_string,
                    'force new connection': true
                #this is a successful login message
                socket.on 'hello', (email) ->
                    broadcast 'loginsuccess',
                        authtoken: authtoken
                        email: email
                    #now that we know who we are, hook up file events
                    socket.emit 'exec',
                        command: 'commitments'
                        args: ['about', 'user', email]
                        , (about) ->
                            socket.itemPath = about.directory
                            socket.emit 'watch', about
                    socket.emit 'exec',
                        command: 'notify'
                        args: ['about', 'user']
                        , (about) ->
                            console.log 'watch', about
                            socket.notifyPath = about.directory
                            socket.emit 'watch', about
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
                socket.on 'addFile', (item) ->
                    if item.filename.indexOf(socket.itemPath) is 0
                        broadcast 'itemfromserver', item.filename, item.data
                    else
                        broadcast 'filefromserver', item.filename, item.data
                socket.on 'changeFile', (item) ->
                    if item.filename.indexOf(socket.itemPath) is 0
                        broadcast 'itemfromserver', item.filename, item.data
                    else
                        broadcast 'filefromserver', item.filename, item.data
                socket.on 'unlinkFile', (item) ->
                    if item.filename.indexOf(socket.itemPath) is 0
                        broadcast 'deleteitemfromserver', item.filename, item.data
                    else
                        broadcast 'deletefilefromserver', item.filename, item.data
            #and now for the event listening
            $rootScope.$on 'login', (event, authtoken) ->
                connect authtoken
            $rootScope.$on 'logout', ->
            $rootScope.$on 'join', (event, email) ->
                connect email, true
                disconnect()
            $rootScope.$on 'itemfromlocal', (event, item) ->
                if socket
                    console.log 'will update', JSON.stringify(item)
                    socket.emit 'exec',
                        command: 'commitments'
                        args: ['update', 'task']
                        stdin: item
            $rootScope.$on 'deleteitemfromlocal', (event, item) ->
                if socket
                    socket.emit 'exec',
                        command: 'commitments'
                        args: ['delete', 'task']
                        stdin: item
            $rootScope.$on 'filefromserver', _.debounce( ->
                    if socket
                        console.log 'going for notifications'
                        socket.emit 'exec',
                            command: 'notify'
                            args: ['peek']
                            , (messages) ->
                                for message in messages
                                    broadcast 'notification', message
                , 500)
            #**used for local testing**
            window.sampleData = ->
                window.FAKE_SERVER = false
                SampleData()
            window.fakeServer = ->
                window.FAKE_SERVER = !window.FAKE_SERVER
            #nothing is returned from this service, on purpose, you just go
            #at it with events
            null
