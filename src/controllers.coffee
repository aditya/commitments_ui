module = angular.module('Root', ['RootServices', 'ui', 'editable', 'readonly'])
    .controller 'Desktop', ($scope, Database, Authentication) ->
        console.log 'desktop'
        $scope.database = Database.sample()
        $scope.selected = $scope.database.boxes[0]
        $scope.user = Authentication.user()
        $scope.selectBox = (box) ->
            $scope.selected = box
        $scope.poke = (item) ->
            console.log 'poking', item
    .controller 'Toolbox', ($scope) ->
        console.log 'toolbox'
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



