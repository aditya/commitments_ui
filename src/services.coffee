module = angular.module('RootServices', [])
    #deal with figuring out who is who
    .factory 'Authentication', ->
        user:
            email: 'wballard@glgroup.com'
    .factory 'Preferences', ->
        ui:
            bulkShareVisible: true
    .factory 'Tags', ->
        []
    #deal with querying 'the database', really the services up in the cloud
    #** for the time being this is just rigged to pretend to be a service **
    .factory 'Database', () ->
        #here is the 'database' in memory, static for now but this will
        #need to be filled in from user home directories
        todos = [
            id: 'a'
            what: 'I am but a simple task'
            due: '02/24/2013'
            tags:
                Tagged: 1
                Important: 1
                'ABC/123': 1
                'ABC/Luv': 1
            who: 'kwokoek@glgroup.com'
            links:
                'igroff@glgroup.com': 1
                'wballard@glgroup.com': 1
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
                    what: 'Yeah! Comments!'
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
    .factory 'StackRank', () ->
        ->
            #standardized sorting function, works to provide per user / per
            #tag stack ranking, with the when creation timestamp providing
            #the tiebreaker, meaning time sorted items go to the end as their
            #indexes are going to be a *lot* larger than 1..n
            sort: (list, user, tag) ->
                user = user or '-'
                tag = tag or '-'
                extractIndex = (item) ->
                    item.when = item.when or Date.now()
                    idx = item?['sort']?[user]?[tag] or item.when
                    idx
                _.sortBy(list, extractIndex)
            renumber: (list, user, tag) ->
                index = 1
                user = user or '-'
                tag = tag or '-'
                for item in list
                    item.sort = item.sort or {}
                    item.sort[user] = item.sort[user] or {}
                    item.sort[user][tag] = index++
    .run ->
        console.log 'starting root services'
