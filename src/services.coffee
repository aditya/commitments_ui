module = angular.module('RootServices', ['ngResource'])
    .factory 'Database', () ->
        sample: ->
            boxes: [
                title: 'Todo'
                uri: '/lists/todo'
                selected: true
                items: [
                    uri: '/items/a'
                    what: 'I am but a simple task'
                    due: '02/24/2013'
                    tags: ['Tagged', 'Important', 'ABC/123', 'ABC/Luv']
                    delegates: ['igroff@glgroup.com']
                ,
                    uri: '/items/b'
                    what: 'There is always more to do'
                    discussion:
                        total: 2
                        comments: [
                            who: 'wballard@glgroup.com'
                            when: '02/21/2013'
                            what: 'Yeah! Comments!\n\nAbout _stuff_...'
                        ,
                            who: 'igroff@glgroup.com'
                            when: '02/24/2013'
                            what: 'Told\n\nYou\n\nSo.'
                        ]
                ]
            ,
                title: 'Done'
                uri: '/lists/done'
                selected: false
            ]
    #nothing in particular to do at the moment for config, it isjust nice to see
    .config ->
        console.log 'Root services online'
    .run ->
        console.log 'starting root services'
