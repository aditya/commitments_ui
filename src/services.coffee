define ['angular',
    'lodash',
    'socketio',
    'cs!src/inverted/inverted',
    'lunr',
    'cs!src/sampledata',
    'cs!src/samplenotifications',
    ], (angular, _, socketio, inverted, lunr, sampledata, samplenotifications) ->
    #fake server, this will fire off a lot of events and generally stress
    #you out while debugging
    window.FAKE_SERVER = false
    module = angular.module('RootServices', [])
        #deal with figuring out who is who
        .factory 'User', ->
            email: 'wballard@glgroup.com'
            preferences:
                bulkShare: false
                server: 'http://localhost:8080/'
                notifications: false
                notificationsLRU: 20
        .factory 'LocalIndexes', ->
            #parsing functions to keep track of all links and tags
            parseTags = (document, callback) ->
                for tag, v of (document?.tags or {})
                    callback tag
            parseLinks = (document, callback) ->
                for link, v of (document?.links or {})
                    callback link
            #inverted indexing for tags
            tagIndex = inverted.index [parseTags], (x) -> x.id
            #inverted indexing for links
            linkIndex = inverted.index [parseLinks], (x) -> x.id
            #full text index for searchacross items
            fullTextIndex = lunr ->
                @field 'what', 8
                @field 'who', 4
                @field 'tags', 2
                @field 'comments', 1
                @ref 'id'
            fullTextIndex.addToIndex = (item) ->
                fullTextIndex.update
                    id: item.id or ''
                    what: item.what or ''
                    who: _.keys(item.links).join ' '
                    tags: (_.keys(item.tags).join ' ') or ''
                    comments: (_.map(
                        item?.discussion?.comments,
                        (x) -> x.what).join ' ') or ''
            do ->
                update: (item) ->
                    #indexing to drive the tags, autocomplete, and screens
                    tagIndex.add item
                    linkIndex.add item
                    fullTextIndex.addToIndex item
                delete: (item) ->
                    tagIndex.remove item
                    linkIndex.remove item
                    fullTextIndex.remove
                        id: item.id
                tags: (filter) ->
                    tagIndex.terms(filter)
                links: (filter) ->
                    linkIndex.terms(filter)
                itemsByTag: (tags, filter) ->
                    tagIndex.search(tags, filter)
                fullTextSearch: (query) ->
                    fullTextIndex.search(query)
        .factory 'Notifications', ($rootScope, $timeout, User) ->
            #items are kept in an LRU buffer
            items = []
            received_items = []
            receive = (message) ->
                received_items.push message
                if received_items.length > User.preferences.notificationsLRU
                    received_items.shift()
            deliver = (message) ->
                items.push message
                if items.length > User.preferences.notificationsLRU
                    items.shift()
            do ->
                unreadCount: ->
                    len = _.keys(received_items).length
                    #This will ba a blank, not a zero
                    len unless not len
                receiveMessage: (message) ->
                    $rootScope.$broadcast 'notification', message
                    if User.preferences.notifications
                        deliver message
                    else
                        receive message
                deliverMessages: ->
                    #move items away from being freshly received
                    for item in received_items
                        deliver item
                    received_items = []
                    items
                items: items
        #deal with querying 'the database', really the services up in the cloud
        #** for the time being this is just rigged to pretend to be a service **
        .factory 'Database', ($rootScope, $timeout, Notifications, LocalIndexes) ->
            #here is the 'database' in memory, items tracked by ID
            items = {}
            opCount = 0
            updateItem = (item, fromServer) ->
                if not fromServer
                    item.lastUpdatedBy = $rootScope.user.email
                    item.lastUpdatedAt = Date.now()
                #merge into the existing object, allowing the data binding
                #to be pointed at the same reference
                if items[item.id]
                    _.extend items[item.id], item
                else
                    items[item.id] = item
                if not fromServer
                    console.log 'update', item, items, 'a'
                else
                    $rootScope.$broadcast 'serverupdate', 'update', item
                opCount++
                LocalIndexes.update item
                item
            deleteItem = (item, fromServer) ->
                delete items[item.id]
                if not fromServer
                    console.log 'delete', item
                else
                    $rootScope.$broadcast 'serverupdate', 'delete', item
                opCount++
                LocalIndexes.delete item
                item
            #start talking to the server when we know who you are, this is
            #how data makes it into the system
            socket = null
            $rootScope.$watch 'user', (user) ->
                if socket
                    socket.disconnect
                socket = socketio.connect user.preferences.server
                #send in a server event into angular
                taskFromServer = (item) ->
                    $rootScope.$apply ->
                        updateItem item, true
                    $rootScope.$digest()
                deleteTaskFromServer = (item) ->
                    $rootScope.$apply ->
                        deleteItem item, true
                    $rootScope.$digest()
                socket.on 'error', ->
                    console.log 'socketerror', arguments
                    #here is some nice fake sample data
                    for item in sampledata
                        updateItem item, true
                    for item in samplenotifications
                        Notifications.receiveMessage item
                    $rootScope.$broadcast 'initialload'
                    fakeCount = 0
                    fakeDeleteCount = 0
                    fakeCommentCount = 0
                    lastAddedId = null
                    id = sampledata[sampledata.length-1].id
                    fakeUpdate = ->
                        $timeout ->
                            if not FAKE_SERVER
                                #no action
                            else
                                #this is making a lot of noise realy to see how
                                #the user interface responds to simulated messages
                                fakeServerUpdate = _.cloneDeep items[id]
                                fakeServerUpdate.what = "Simulated event update #{Date.now()}"
                                if fakeCommentCount++ < 10
                                    fakeServerUpdate.discussion.comments.push
                                        who: 'igroff@glgroup.com'
                                        when: new Date().toDateString()
                                        what: "Simulated comment #{Date.now()}"
                                if fakeCount++ < 5
                                    fakeServerUpdate.tags["Tag #{fakeCount}"] = Date.now()
                                else
                                    if fakeDeleteCount++ < 5
                                        delete fakeServerUpdate.tags["Tag #{fakeDeleteCount}"]
                                    else
                                        fakeDeleteCount = 0
                                        fakeCount = 0
                                #an update
                                taskFromServer fakeServerUpdate
                                #delete the last add
                                deleteTaskFromServer
                                    id: lastAddedId
                                #a new task
                                lastAddedId = Date.now()
                                taskFromServer
                                    id: lastAddedId
                                    what: "Inserted #{Date.now()}"
                                    who: user.email
                                Notifications.receiveMessage
                                    when: Date.now()
                                    data:
                                        message: "Hello there, I am a fresh notification #{Date.now()}"

                            fakeUpdate()
                        , 1000
                    fakeUpdate()
                socket.on 'connect', ->
                    console.log 'connected'
            , true
            #here is the database service construction function itself
            #call this in controllers, or really - just the root most controller
            #to get one database
            do ->
                items: (filter) ->
                    _.filter _.values(items), filter
                update: updateItem
                delete: deleteItem
                opCount: -> opCount
                tags: LocalIndexes.tags
                links: LocalIndexes.links
                itemsByTag: LocalIndexes.itemsByTag
                fullTextSearch: LocalIndexes.fullTextSearch
                notifications: Notifications
        #
        .factory 'StackRank', () ->
            do ->
                #standardized sorting function, works to provide per user / per
                #tag stack ranking, with the when creation timestamp providing
                #the tiebreaker, meaning time sorted items go to the end as their
                #indexes are going to be a *lot* larger than 1..n
                sort: (list, user, tag) ->
                    user = user or '-'
                    tag = tag or '-'
                    extractIndex = (item) ->
                        item.when = item.when or Date.now()
                        idx = item?['sort']?[user]?[tag] or item.when
                        idx
                    _.sortBy(list, extractIndex)
                renumber: (list, user, tag) ->
                    index = 1
                    user = user or '-'
                    tag = tag or '-'
                    for item in list
                        item.sort = item.sort or {}
                        item.sort[user] = item.sort[user] or {}
                        item.sort[user][tag] = index++
