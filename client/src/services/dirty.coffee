###
Track read/dirty flags.
###
define ['angular',
    'store',
    'cs!./root'], (angular, store, root) ->
        root.factory 'Dirty', ($rootScope, User) ->
            #selecting a record clears the dirty
            $rootScope.$on 'focusedrecord', (event, item) ->
                flagTo = Date.now()
                store.set item.id, flagTo
                #put this on the service, that way when it is in scope, it can
                #be used for binding
                service.updated = item.id
            #just use a local store for dirty tracking at the moment
            service =
                unview: (item) ->
                    store.remove item.id
                dirty: (item, dirtval) ->
                    console.log 'dirtbag', item, dirtval
                    dirtflag = Number(store.get(item.id) or 0)
                    return dirtval > dirtflag
