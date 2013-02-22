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
                    due: '02/24/2013'
                    tags: ['Tagged', 'Important', 'ABC/123', 'ABC/Luv']
                    delegates: ['ian.groff@glgroup.com']
                ,
                    link: '/items/b'
                    message: 'There is always more to do'

                ]
            ,
                name: 'Done'
                link: '/lists/done'
                selected: false
            ]
    .config ->
        console.log 'Root services online'
    .run ->
        console.log 'starting root services'
