module = angular.module('RootServices', ['ngResource'])
    #deal with figuring out who is who
    .factory 'Authentication', ->
        user: ->
            email: 'wballard@glgroup.com'
    #deal with querying 'the database', really the services up in the cloud
    #** for the time being this is just rigged to pretend to be a service **
    .factory 'Database', () ->
        todos = [
            what: 'I am but a simple task\n\n* One\n\n* Two'
            due: '02/24/2013'
            tags: ['Tagged', 'Important', 'ABC/123', 'ABC/Luv']
            who: 'kwokoek@glgroup.com'
            delegates: ['igroff@glgroup.com', 'wballard@glgroup.com']
        ,
            what: 'There is always more to do'
            who: 'wballard@glgroup.com'
            discussion:
                total: 2
                show: true
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
        sample: ->
            boxes: [
                title: 'Todo'
                filter: -> _.reject(todos, (x) -> x.done)
                hide: (x) -> x.done
            ,
                title: 'Done'
                filter: -> _.filter(todos, (x) -> x.done)
                hide: (x) -> not x.done
            ]
            items: todos
    #nothing in particular to do at the moment for config, it isjust nice to see
    .config ->
        console.log 'Root services online'
    .run ->
        console.log 'starting root services'
