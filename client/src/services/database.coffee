###
This is the in memory database, containing the actual items being edited. It
is supplied from user input, SampleData, and the Server.
###
define ['angular',
    'store',
    'cs!./root',
    'cs!./sampledata',
    'cs!./localindexes'], (angular, store, root) ->
        root.factory 'Database', ($rootScope, $timeout, LocalIndexes, SampleData) ->
            #here is the 'database' in memory, items tracked by ID
            items = {}
            items_by_file = {}
            updateItem = (item, filename) ->
                if not item
                    return
                if not filename
                    #this came from a local update, not back from the server
                    #so send it along
                    item.lastUpdatedBy = $rootScope.user.email
                    item.lastUpdatedAt = Date.now()
                    items[item.id] = item
                else
                    items_by_file[filename] = item
                    #just in case these snuck in, no need to taunt angular
                    #with its hidden variables since these came from out of the
                    #current angular application
                    delete item['$$hashKey']
                    #this came from a remote update, so new data needs to be
                    #merge into the existing object, allowing the data binding
                    #to be pointed at the same reference
                    if items[item.id]
                        _.extend items[item.id], item
                    else
                        items[item.id] = item
                        #this is queued on purpose, that way the local indexes
                        #are all updated and this event can be listend from the
                        #UI to redraw post those local index changes. all event
                        #driven anyhow, coming back from the server, if this was
                        #synchronous, it would be before the indexes were updated
                        #below...
                        $timeout ->
                            $rootScope.$broadcast 'newitemfromserver', item
                LocalIndexes.update item, items
                item
            deleteItem = (item, filename) ->
                item = item or items_by_file[filename]
                console.log 'delete', item, filename
                if not item
                    return
                #removal of the item from the local database
                delete items[item.id]
                LocalIndexes.delete item, items
                item
            #here is the database service construction function itself
            #call this in controllers, or really - just the root most controller
            #to get one database
            database =
                items: (filter) ->
                    _.filter _.values(items), filter
                item: (id) ->
                    items[id]
            #event handlers
            $rootScope.$on 'loginsuccess', ->
                items = {}
            $rootScope.$on 'reconnect', ->
                #save everything if there was a reconnect, safety-pup!
                for item in _.values(items)
                    $rootScope.$broadcast 'itemfromlocal', item
            $rootScope.$on 'itemfromserver', (event, filename, item) ->
                updateItem item, filename
            $rootScope.$on 'deleteitemfromserver', (event, filename, item) ->
                deleteItem item, filename
            $rootScope.$on 'itemfromlocal', (event, item) ->
                updateItem item
            $rootScope.$on 'deleteitemfromlocal', (event, item) ->
                deleteItem item
            $rootScope.$on 'archiveitemfromlocal', (event, item) ->
                deleteItem item
            database
