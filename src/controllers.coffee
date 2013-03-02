module = angular.module('Root', ['RootServices', 'ui', 'editable', 'readonly'])
    .controller 'Desktop', ($scope, Database, Authentication) ->
        console.log 'desktop'
        $scope.database = Database()
        $scope.user = Authentication.user()
        $scope.updates = 0
        $scope.selectBox = (box) ->
            $scope.selected = box
            $scope.selected.items = box.filter()
            console.log $scope.selected.items
        $scope.poke = (item) ->
            console.log 'poking', item
        $scope.newItem = (item) ->
            console.log 'new item', item
            $scope.database.items.push item
            $scope.updates++
        $scope.updateItem = (item) ->
            console.log 'update item', item
            $scope.updates++
        $scope.deleteItem  = (item) ->
            console.log 'delete item', item
            list = $scope.database.items
            foundAt = list.indexOf(item)
            if foundAt >= 0
                list.splice(foundAt, 1)
            $scope.updates++
        #initial view selection
        $scope.selectBox $scope.database.boxes[0]
    .controller 'Toolbox', ($scope, $rootScope) ->
        console.log 'toolbox'
        me = $scope.user.email
        $scope.$watch 'updates', ->
            boxes = [].concat($scope.boxes, $scope.tags)
            for box in boxes
                box.todo_count = _.reject(box.filter(),
                    (x) -> x.done or (x.who isnt me and not x.delegates[me])).length
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



