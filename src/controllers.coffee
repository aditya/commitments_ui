module = angular.module('Root', ['RootServices', 'ui', 'editable', 'readonly'])
    .controller 'Desktop', ($scope, Database, Authentication) ->
        console.log 'desktop'
        $scope.tagNamespaceSeparators = [':', '/']
        $scope.database = Database()
        $scope.user = Authentication.user()
        $scope.messages =
            info: 'Alerts & Messages'
            count: 0
        $scope.updates = 0
        $scope.selectBox = (box) ->
            $scope.selected = box
            $scope.selected.items = box.filter()
        $scope.poke = (item) ->
            console.log 'poking', item
        $scope.newItem = (item) ->
            console.log 'new', item
            $scope.database.items.push item
            $scope.lastUpdatedItem = item
        $scope.updateItem = (item) ->
            console.log 'update', item
            $scope.lastUpdatedItem = item
        $scope.deleteItem  = (item) ->
            console.log 'delete', item
            list = $scope.database.items
            foundAt = list.indexOf(item)
            if foundAt >= 0
                list.splice(foundAt, 1)
                $scope.lastDeletedItem = item
        #initial view selection
        $scope.selectBox $scope.database.boxes[0]
    .controller 'Toolbox', ($scope, $rootScope) ->
        console.log 'toolbox'
        me = $scope.user.email
        #just pick out tags from a todo
        parseTags = (context) ->
            (document, callback) ->
                for tag, _ of (document?.tags or {})
                    callback tag
        #boolean, done or not?
        isDone = (context) ->
            (document, callback) ->
                callback (document?.done or false)
        tagIndex = inverted.index $scope, [parseTags]
        doneIndex = inverted.index $scope, [isDone]
        indexItem = (item) ->
            console.log 'indexing', item
            tagIndex.add item
            doneIndex.add item
        $scope.$watch 'database', (database) ->
            console.log 'reindexing'
            do tagIndex.clear
            do doneIndex.clear
            for item in database.items
                indexItem item
            tags = []
            for tag in tagIndex.terms()
                byTag = (tagValue) ->
                    by_tag = {tags: {}}
                    by_tag.tags[tagValue] = 1
                    -> tagIndex.search by_tag
                stillToDo = -> doneIndex.search {done: false}
                tags.push
                    title: tag
                    hide: -> false
                    filter: byTag tag
                    todoCount: -> 0
            $scope.tags = tags
            console.log 'reindexing complete'
        $scope.$watch 'lastUpdatedItem', (item) ->
            indexItem item
        $scope.$watch 'lastDeletedItem', (item) ->
            indexItem item
        #and here are the todo and done boxes
        $scope.boxes = $scope.database.boxes
    .controller 'Discussion', ($scope) ->
        console.log 'comments'
    .controller 'TaskAccept', ($scope, $timeout) ->
        console.log 'accept'
        $scope.accept = (item) ->
            item.accept[$scope.user.email] = Date.now()
        $scope.reject = (item) ->
            delete item.delegates[$scope.user.email]
            delete item.accept[$scope.user.email]
    .config ->
        console.log 'Root controllers online'
    .run ->
        console.log 'starting application'



