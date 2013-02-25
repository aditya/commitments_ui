module = angular.module('Root', ['RootServices', 'ui', 'dynamic', 'editable', 'readonly'])
    .controller 'Desktop', ($scope, $compile, Database) ->
        console.log 'desktop'
        $scope.database = Database.sample()
        $scope.selected = $scope.database.boxes[0]
    .controller 'Toolbox', ($scope) ->
        console.log 'toolbox'
    .controller 'Discussion', ($scope) ->
        console.log 'comments'
    .config ->
        console.log 'Root controllers online'
    .run ->
        console.log angular.element(document)
        console.log 'starting application'



