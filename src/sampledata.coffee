#Build up some sample data for UI testing, this is used when we don't have
#a server going to allow interactive testing
define ->
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
