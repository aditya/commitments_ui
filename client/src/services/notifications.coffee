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
            newCount = 0
            receive = (message) ->
                #unshift to make the most recent message the first
                items.unshift message
                if items.length > User.preferences.notificationsLRU
                    items.pop()
                newCount = items.length
            notification =
                unreadCount: ->
                    #This will ba a blank, not a zero
                    newCount unless not newCount
                receiveMessage: (message) ->
                    receive message
                deliverMessages: ->
                    newCount = 0
                items: items
                itemCount: ->
                    items.length
                clear: ->
                    items.splice()
            #event handling
            $rootScope.$on 'notification', (event, message) ->
                notification.receiveMessage message
            #the service
            notification
