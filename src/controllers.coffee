module = angular.module('Root', ['RootServices', 'ui', 'dynamic', 'editable', 'readonly'])
    .controller 'Desktop', ($scope, $compile, Database, Authentication) ->
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
    .config ->
        console.log 'Root controllers online'
    .run ->
        console.log angular.element(document)
        console.log 'starting application'



