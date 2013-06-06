###
Task service, this provides the needed action verbs in one place so that
it is a bit easier to see.
###
define ['angular',
    'lodash',
    'cs!./root'], (angular, _, root) ->
        root.factory 'Task', ($rootScope, User) ->
            do ->
                new: (item) ->
                    if not item.who
                        item.who = User.email
                    if not item.id
                        item.id = md5("#{Date.now()}")
                    if not item.when
                        item.when = Date.now()
                accept: (item) ->
                    item.links[User.email] = Date.now()
                    item.accept[User.email] = Date.now()
                    delete item.reject[User.email]
                    $rootScope.$broadcast 'itemfromlocal', item
                reject: (item) ->
                    item.reject[User.email] = Date.now()
                    delete item.links[User.email]
                    delete item.accept[User.email]
                    $rootScope.$broadcast 'itemfromlocal', item

