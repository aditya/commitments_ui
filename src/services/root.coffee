module = angular.module('RootServices', ['ngResource'])
    .factory 'Database', () ->
        sample: ->
            boxes: ['Todo', 'Delegated', 'Done']
    .config ->
        console.log 'Root services online'
    .run ->
        console.log 'starting root services'
