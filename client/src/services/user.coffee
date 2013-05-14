###
Keep track of the current user, including the ability to log in
and log out.
###
define ['angular',
    'store',
    'cs!./root'], (angular, store, root) ->
        root.factory 'User', ($rootScope) ->
            $rootScope.sampleUsers =
                'wballard@glgroup.com': 'xxx'
                'igroff@glgroup.com': 'yyy'
                'kwokoek@glgroup.com': 'zzz'
            #since we have to talk to the serve to know if we are logged in
            #this comes back as an event
            $rootScope.$on 'loginsuccess', (event, identity) ->
                user.persistentIdentity identity
            $rootScope.$on 'logout', (event, identity) ->
                user.persistentIdentity {}
            user =
                email: ''
                authtoken: ''
                preferences:
                    bulkShare: false
                    server: "http://#{window.location.host}/"
                    notifications: false
                    notificationsLRU: 20
                persistentIdentity: (identity) ->
                    #this is a getter with no args
                    if arguments.length
                        store.set 'identity', identity
                        user.email = identity?.email
                        user.authtoken = identity?.authtoken
                    store.get 'identity'
                lastLocation: (location) ->
                    #getter with no args
                    if arguments.length
                        store.set 'lastLocation', location
                    store.get 'lastLocation'
            #expose the methods with a variable, this is allowing self-reference
            #updates in the implementation above
            user
