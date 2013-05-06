#Some nice sample notifications
samplenotifications =
    [
        when: 1366569723607
        data:
            tags: [ 'info' ]
            message: 'Hello, there has been an update and this is a lot of text...'
    ,
        when: 1366569734241
        data:
            tags: [ 'info' ]
            message: 'Hello Again'

    ]
#Build up some sample data for UI testing, this is used when we don't have
#a server going to allow interactive testing
sampledata =
    [
    #this one is pretending to be a shared task
        id: 'a'
        what: 'I am but a simple task'
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
        tags: {}
        links:
            'igroff@glgroup.com': 1
            'kwokoek@glgroup.com': 1
        discussion:
            comments: []
    ]
#and here is a module to make use of the sample data
define ['angular',
    'lodash'
    ], (angular, _) ->
        module = angular.module('SampleData', [])
            #deal with sample data for local testing
            .factory 'SampleData', ($rootScope, $timeout) ->
                (taskFromServer, deleteTaskFromServer, notification, email) ->
                    #here is some nice fake sample data, but only if we got
                    #a fake user, this is much like connecting to the server
                    #in that if we failed to authenticate, there would be
                    #no messages
                    for item in sampledata
                        cloneFromItem = item
                        taskFromServer item
                    for item in samplenotifications
                        notification item
                    fakeCount = 0
                    fakeDeleteCount = 0
                    fakeCommentCount = 0
                    lastAddedId = null
                    id = sampledata[sampledata.length-1].id
                    fakeUpdate = ->
                        $timeout ->
                            if not window.FAKE_SERVER
                                #no action
                            else
                                #this is making a lot of noise realy to see how
                                #the user interface responds to simulated messages
                                fakeServerUpdate = _.cloneDeep cloneFromItem
                                fakeServerUpdate.what = "Simulated event update #{Date.now()}"
                                if fakeCommentCount++ < 10
                                    fakeServerUpdate.discussion.comments.push
                                        who: 'igroff@glgroup.com'
                                        when: new Date().toDateString()
                                        what: "Simulated comment #{Date.now()}"
                                if fakeCount++ < 5
                                    fakeServerUpdate.tags["Tag #{fakeCount}"] = Date.now()
                                else
                                    if fakeDeleteCount++ < 5
                                        delete fakeServerUpdate.tags["Tag #{fakeDeleteCount}"]
                                    else
                                        fakeDeleteCount = 0
                                        fakeCount = 0
                                #an update
                                taskFromServer fakeServerUpdate
                                #delete the last add
                                deleteTaskFromServer
                                    id: lastAddedId
                                #a new task
                                lastAddedId = Date.now()
                                taskFromServer
                                    id: lastAddedId
                                    what: "Inserted #{Date.now()}"
                                    who: email
                                notification
                                    when: Date.now()
                                    data:
                                        message: "Hello there, I am a fresh notification #{Date.now()}"
                            fakeUpdate()
                        , 1000
                    fakeUpdate()
