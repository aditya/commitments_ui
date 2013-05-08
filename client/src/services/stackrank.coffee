###
Stack ranking service, maintains properties and data for drag and drop
stack ranking of lists.
###
define ['angular',
    'store',
    'cs!./root'], (angular, store, root) ->
        root.factory 'StackRank', () ->
            do ->
                #standardized sorting function, works to provide per user / per
                #tag stack ranking, with the when creation timestamp providing
                #the tiebreaker, meaning time sorted items go to the end as their
                #indexes are going to be a *lot* larger than 1..n
                sort: (list, key, tag) ->
                    stack = store.get(tag) or {}
                    extractIndex = (item) ->
                        item.when = item.when or Date.now()
                        stack[key(item)] or item.when
                    _.sortBy(list, extractIndex)
                renumber: (list, key, tag) ->
                    stack = store.get(tag) or {}
                    index = 1
                    for item in list
                        stack[key(item)] = index++
                    store.set tag, stack
