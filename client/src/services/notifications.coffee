###
Notification message service, keeps the in memory notification database.
###
define ['angular',
    'lodash',
    'cs!./root',
    'cs!./user'], (angular, _, root) ->
        root.factory 'Notifications', ($rootScope, $timeout, User) ->
            #items are kept in an LRU buffer
            items = []
            received_items = []
            receive = (message) ->
                received_items.push message
                if received_items.length > User.preferences.notificationsLRU
                    received_items.shift()
            deliver = (message) ->
                items.push message
                if items.length > User.preferences.notificationsLRU
                    items.shift()
            notification =
                unreadCount: ->
                    len = _.keys(received_items).length
                    #This will ba a blank, not a zero
                    len unless not len
                receiveMessage: (message) ->
                    if User.preferences.notifications
                        deliver message
                    else
                        receive message
                deliverMessages: ->
                    #move items away from being freshly received
                    for item in received_items
                        deliver item
                    received_items = []
                    items
                items: items
                clear: ->
                    items.splice()
                    received_items.splice()
            #event handling
            $rootScope.$on 'notification', (event, message) ->
                notification.receiveMessage message
            #the service
            notification
