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
            #here is the 'database' in memory, items tracked by ID and file
            items = {}
            items_by_file = {}
            items_in_order = []
            #
            updateItem = (item, fromserver, filename) ->
                console.log 'database'
                if not item
                    return
                if not fromserver
                    #all local updates change metadata
                    item.lastUpdatedBy = $rootScope.user.email
                    item.lastUpdatedAt = Date.now()
                else
                    #just in case these snuck in, no need to taunt angular
                    #with its hidden variables since these came from out of the
                    #current angular application
                    delete item['$$hashKey']
                #file to item tracking
                if filename
                    items_by_file[filename] = item
                #this may come from a remote update, so new data needs to be
                #merge into the existing object, allowing the data binding
                #to be pointed at the same reference
                if items[item.id]
                    _.extend items[item.id], item
                else
                    items[item.id] = item
                    if _.indexOf(items_in_order, item) is -1
                        items_in_order.push item
                LocalIndexes.update item, items
                item
            #
            deleteItem = (item, fromserver, filename) ->
                item = item or items_by_file[filename]
                if item
                    #removal of the item from the local database
                    delete items[item.id]
                    #and from the sorted list
                    idx = _.findIndex items_in_order, (x) -> x.id is item.id
                    if idx > -1
                        items_in_order.splice idx, 1
                    LocalIndexes.delete item, items
                item
            #here is the database service construction function itself
            #call this in controllers, or really - just the root most controller
            #to get one database
            database =
                items: items_in_order
            #save everything if there was a reconnect, safety-pup!
            $rootScope.$on 'reconnect', ->
                for item in _.values(items)
                    $rootScope.$broadcast 'updateitem', item
            #every item from the server, replaces the world
            $rootScope.$on 'itemsfromserver', (event, serveritems) ->
                items = {}
                items_by_file = {}
                items_in_order.splice 0
                for item in serveritems
                    updateItem item, true
            #single item update
            $rootScope.$on 'itemfromserver', (event, filename, item) ->
                updateItem item, true, filename
            $rootScope.$on 'deleteitemfromserver', (event, filename, item) ->
                deleteItem item, true, filename
            $rootScope.$on 'updateitem', (event, item) ->
                updateItem item
            $rootScope.$on 'deleteitem', (event, item) ->
                deleteItem item
            $rootScope.$on 'archiveitem', (event, item) ->
                deleteItem item
            database
