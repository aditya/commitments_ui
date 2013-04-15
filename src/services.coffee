define ['angular',
    'lodash',
    'socketio',
    'cs!src/inverted/inverted',
    'lunr',
    'cs!src/sampledata',
    ], (angular, _, socketio, inverted, lunr, sampledata) ->
    module = angular.module('RootServices', [])
        #deal with figuring out who is who
        .factory 'User', ->
            ->
                email: 'wballard@glgroup.com'
                preferences:
                    bulkShare: false
                    server: 'http://localhost:8080/'
        #deal with querying 'the database', really the services up in the cloud
        #** for the time being this is just rigged to pretend to be a service **
        .factory 'Database', ($rootScope) ->
            #here is the 'database' in memory, items tracked by ID
            items = {}
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
            updateItem = (item, fromServer) ->
                if not fromServer
                    console.log 'update', JSON.stringify(item)
                else
                    console.log 'serverupdate', JSON.stringify(item)
                items[item.id] = item
                tagIndex.add item
                linkIndex.add item
                fullTextIndex.addToIndex item
                item
            deleteItem = (item, fromServer) ->
                if not fromServer
                    console.log 'delete', item
                else
                    console.log 'serverdelete', item
                delete items[item.id]
                tagIndex.remove item
                linkIndex.remove item
                fullTextIndex.remove
                    id: item.id
                item
            #start talking to the server when we know who you are, this is
            #how data makes it into the system
            socket = null
            $rootScope.$watch 'user', (user) ->
                if socket
                    socket.disconnect
                socket = socketio.connect user.preferences.server
                socket.on 'error', ->
                    console.log 'socketerror', arguments
                    for item in sampledata
                        updateItem item, true
                    $rootScope.$broadcast 'initialload'
                socket.on 'connect', ->
                    console.log 'connected'
            , true
            #here is the database service construction function itself
            #call this in controllers, or really - just the root most controller
            #to get one database
            ->
                items: (filter) ->
                    _.filter _.values(items), filter
                tagIndex: tagIndex
                fullTextIndex: fullTextIndex
                update: updateItem
                delete: deleteItem
        #
        .factory 'StackRank', () ->
            ->
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
