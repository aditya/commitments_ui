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
            console.log $scope.selected.items
        $scope.poke = (item) ->
            console.log 'poking', item
        $scope.newItem = (item) ->
            $scope.database.items.push item
            $scope.lastUpdatedItem = item
        $scope.updateItem = (item) ->
            $scope.lastUpdatedItem = item
        $scope.deleteItem  = (item) ->
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
        parseTags = (context) ->
            pattern = new RegExp("[" + $scope.tagNamespaceSeparators.join("") + "]+", "g");
            (document, callback) ->
                for tag, _ of (document?.tags or {})
                    callback tag
        index = inverted $scope,
            tags: [parseTags]
            #done: []
            #text: []
        $scope.$watch 'database', (database) ->
            console.log 'reindexing'
            do index.clear
            for item in database.items
                index.add item
        $scope.$watch 'lastUpdatedItem', (item) ->
            index.add item
        $scope.$watch 'lastDeletedItem', (item) ->
            index.remove item
        #and here are the boxes, first get all the tags -- nothing super fancy
        $scope.boxes = $scope.database.boxes
        #and the dynamic tag boxes
        tags = {}
        for item in $scope.database.items
            if item.tags?
                for tag in item.tags
                    tags[tag] =
                        title: tag
                        filter: -> _.filter($scope.database.items, (x) -> (x.tags or{})[tag])
                        hide: -> false
        $scope.tags = _.values(tags)
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



