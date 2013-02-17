module = angular.module('Root', ['RootServices', 'ui', 'dynamic'])
    .controller 'Desktop', ($scope, $compile, Database) ->
        $scope.database = Database.sample()
    .config ->
        console.log 'Root controllers online'
    .run ->
        console.log angular.element(document)
        console.log 'starting application'



