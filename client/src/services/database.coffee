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
            #things in from the server are tracked, this is storing ids to
            #avoid thinking about if objects are updated or cloned
            items_from_server = {}
            updateItem = (item, fromServer) ->
                if not item
                    return
                if not fromServer
                    #this came from a local update, not back from the server
                    #so send it along
                    item.lastUpdatedBy = $rootScope.user.email
                    item.lastUpdatedAt = Date.now()
                else
                    #just in case these snuck in, no need to taunt angular
                    #with its hidden variables since these came from out of the
                    #current angular application
                    delete item['$$hashKey']
                    #track that it came from the server
                    items_from_server[fromServer] = item.id
                    #this came from a remote update, so new data needs to be
                    #merge into the existing object, allowing the data binding
                    #to be pointed at the same reference
                    if items[item.id]
                        _.extend items[item.id], item
                    else
                        items[item.id] = item
                LocalIndexes.update item
                item
            deleteItem = (item, fromServer) ->
                if not item
                    return
                #removal of the item from the local database
                delete items[item.id]
                LocalIndexes.delete item
                item
            #here is the database service construction function itself
            #call this in controllers, or really - just the root most controller
            #to get one database
            database =
                items: (filter) ->
                    _.filter _.values(items), filter
                tags: LocalIndexes.tags
                links: LocalIndexes.links
                itemsByTag: LocalIndexes.itemsByTag
                fullTextSearch: LocalIndexes.fullTextSearch
            #event handlers
            $rootScope.$on 'loginsuccess', ->
                items = {}
                items_from_server = {}
            $rootScope.$on 'itemfromserver', (event, filename, item) ->
                updateItem item, filename
            $rootScope.$on 'deleteitemfromserver', (event, filename, item) ->
                deleteItem item, filename
            $rootScope.$on 'itemfromlocal', (event, item) ->
                updateItem item
            $rootScope.$on 'deleteitemfromlocal', (event, item) ->
                deleteItem item
            database
