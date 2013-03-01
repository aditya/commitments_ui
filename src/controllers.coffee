module = angular.module('Root', ['RootServices', 'ui', 'editable', 'readonly'])
    .controller 'Desktop', ($scope, Database, Authentication) ->
        console.log 'desktop'
        $scope.database = Database.sample()
        $scope.user = Authentication.user()
        $scope.selectBox = (box) ->
            $scope.selected = box
            $scope.selected.items = box.filter()
            $scope.selected.items.pusher = (x) ->
                $scope.database.items.push x
            console.log $scope.selected.items
        $scope.poke = (item) ->
            console.log 'poking', item
        #initial view selection
        $scope.selectBox $scope.database.boxes[0]
    .controller 'Toolbox', ($scope, $rootScope) ->
        console.log 'toolbox'
        $rootScope.$on 'recount', ->
            for box in $scope.database.boxes
                box.todo_count = _.reject(box.filter(), (x) -> x.done or x.$$placeholder).length
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



