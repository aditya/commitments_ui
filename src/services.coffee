module = angular.module('RootServices', ['ngResource'])
    #deal with figuring out who is who
    .factory 'Authentication', ->
        user: ->
            email: 'wballard@glgroup.com'
    #deal with querying 'the database', really the services up in the cloud
    #** for the time being this is just rigged to pretend to be a service **
    .factory 'Database', () ->
        #here is the 'database' in memory, static for now but this will
        #need to be filled in from user home directories
        todos = [
            id: 'a'
            what: 'I am but a simple task\n\n* One\n\n* Two'
            due: '02/24/2013'
            tags:
                Tagged: 1
                Important: 1
                'ABC/123': 1
                'ABC/Luv': 1
            who: 'kwokoek@glgroup.com'
            delegates: ['igroff@glgroup.com', 'wballard@glgroup.com']
        ,
            id: 'b'
            what: 'There is always more to do'
            who: 'wballard@glgroup.com'
            tags:
                Tagged: 1
            discussion:
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
        ,
            id: 'c'
            what: 'Nothing fancy'
            who: 'wballard@glgroup.com'
        ]
        ->
            items: todos
    #nothing in particular to do at the moment for config, it isjust nice to see
    .config ->
        console.log 'Root services online'
    .run ->
        console.log 'starting root services'
