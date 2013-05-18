###
Trashcan service. When you delete a task, this will listen in
and save a local copy for you to allow easy undelete.
###
define ['angular',
    'store',
    'lodash',
    'cs!./root'], (angular, store, _, root) ->
        root.factory 'Trash', ($rootScope) ->
            trashcan = store.get('.trash') or {}
            $rootScope.$on 'deleteitem', (event, item) ->
                #such a very primitize API to get at local storage, not that
                #it is a big deal to JSON things, but incremental adding
                #would be preferred to me
                trashcan = store.get('.trash') or {}
                trashcan[item.id] = item
                store.set '.trash', trashcan
            untrash = (item) ->
                #just make sure the item isn't in the trash
                trashcan = store.get('.trash') or {}
                delete trashcan[item.id]
                store.set '.trash', trashcan
            $rootScope.$on 'itemfromlocal', (event, item) ->
                #you undeleted the thing
                untrash item
            $rootScope.$on 'itemfromserver', (event, item) ->
                #somebody else may have undeleted the thing
                untrash item
            do ->
                items: ->
                    trashcan
                itemCount: ->
                    _.keys(trashcan).length
