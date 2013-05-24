###
Stack ranking service, maintains properties and data for drag and drop
stack ranking of lists.
###
define ['angular',
    'store',
    'cs!./root'], (angular, store, root) ->
        root.factory 'StackRank', (User) ->
            do ->
                #standardized sorting function, works to provide per user / per
                #tag stack ranking, with the when creation timestamp providing
                #the tiebreaker, meaning time sorted items go to the end as their
                #indexes are going to be a *lot* larger than 1..n
                comparator: (item) ->
                    #this will modify the object
                    item.when = item.when or Date.now()
                    #this won't add to an object, just look up lazy
                    item_stack = item.stackRank or {}
                    item_stack[User.email] or item.when
                renumber: (list) ->
                    index = 1
                    for item in list
                        item_stack = item.stackRank = item.stackRank or {}
                        item_stack[User.email] = index++
