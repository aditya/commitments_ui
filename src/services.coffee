module = angular.module('RootServices', ['ngResource'])
    .factory 'Database', () ->
        sample: ->
            boxes:
                Todo:
                    link: ''
                Delegated:
                    link: ''
                Done:
                    link: ''
    .config ->
        console.log 'Root services online'
    .run ->
        console.log 'starting root services'
