module = angular.module('RootServices', ['ngResource'])
    .factory 'Database', () ->
        sample: ->
            boxes:
                Todo:
                    link: '/lists/todo'
                    selected: true
                    items: [
                        link: '/items/a'
                        message: 'I am but a simple task'
                    ,
                        link: '/items/b'
                        message: 'There is always more to do'

                    ]
                Delegated:
                    link: '/lists/delegated'
                    selected: false
                Done:
                    link: '/lists/done'
                    selected: false
    .config ->
        console.log 'Root services online'
    .run ->
        console.log 'starting root services'
