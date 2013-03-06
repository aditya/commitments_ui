module = angular.module('Root', ['RootServices', 'ui', 'editable', 'readonly'])
    .controller 'Desktop', ($scope, Database, Authentication) ->
        console.log 'desktop'
        $scope.tagNamespaceSeparators = [':', '/']
        $scope.database = Database()
        $scope.user = Authentication.user()
        $scope.messages =
            info: 'Alerts & Messages'
            count: 0
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
    .controller 'Toolbox', ($scope, $rootScope) ->
        console.log 'toolbox'
        #always have the todo and done boxes
        $scope.boxes = [
            title: 'Todo'
            filter: -> _.reject($scope.database.items, (x) -> x.done)
            hide: (x) -> x.done
        ,
            title: 'Done'
            filter: -> _.filter($scope.database.items, (x) -> x.done)
            hide: (x) -> not x.done
        ]
        #initial view selection
        $scope.selectBox $scope.boxes[0]
        #just pick out tags from a todo, these will be facets
        parseTags = (document, callback) ->
            for tag, _ of (document?.tags or {})
                callback tag
        tagIndex = $scope.tagIndex = inverted.index [parseTags], (x) -> x.id
        #any time the database changes, we need to build a whole new tag
        #index
        $scope.$watch 'database', (database) ->
            console.log 'reindexing'
            do tagIndex.clear
            for item in database.items
                tagIndex.add item
            console.log 'reindexing complete'
        #watch the index for changes, and if you see them rebuild all the tags
        #so that we track the currently available facets
        $scope.$watch 'tagIndex.revision()', ->
            $scope.tags = do ->
                ret = []
                for tag in tagIndex.terms()
                    byTag = (tag, filter) ->
                        () ->
                            by_tag = {tags: {}}
                            by_tag.tags[tag] = 1
                            tagIndex.search by_tag, filter
                    ret.push
                        title: tag
                        hide: -> false
                        filter: byTag(tag)
                        todoCount: byTag(tag, (x) -> not x.done)
                ret
        #peek at the model to see when it it time to add or remove an item
        $scope.$watch 'lastUpdatedItem', (item) ->
            tagIndex.add item
        , true
        $scope.$watch 'lastDeletedItem', (item) ->
            tagIndex.remove item
        , true
        #and here are the todo and done boxes
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



