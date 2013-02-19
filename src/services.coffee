module = angular.module('RootServices', ['ngResource'])
    .factory 'Database', () ->
        sample: ->
            boxes: [
                name: 'Todo'
                link: '/lists/todo'
                selected: true
                items: [
                    link: '/items/a'
                    message: 'I am but a simple task'
                    tags: ['Tagged', 'Important']
                ,
                    link: '/items/b'
                    message: 'There is always more to do'

                ]
            ,
                name: 'Delegated'
                link: '/lists/delegated'
                selected: false
            ,
                name: 'Done'
                link: '/lists/done'
                selected: false
            ]
    .config ->
        console.log 'Root services online'
    .run ->
        console.log 'starting root services'
