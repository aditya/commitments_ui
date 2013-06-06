###
Task service, this provides the needed action verbs in one place so that
it is a bit easier to see.
###
define ['angular',
    'lodash',
    'cs!./root'], (angular, _, root) ->
        root.factory 'Task', ($timeout, $rootScope, User) ->
            do ->
                new: (task) ->
                    if not task.who
                        task.who = User.email
                    if not task.id
                        task.id = md5("#{Date.now()}")
                    if not task.when
                        task.when = Date.now()
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
                subtask: (task) ->
                    task.subitems = task.subitems or []
                    #only make a new record if the current blank is 'used up'
                    if (task.subitems.length is 0) or (_.last(task.subitems)?.what)
                        blank_record =
                            id: md5(Date.now() + '')
                        task.subitems.push blank_record
                        blank_record
                    else
                        _.last task.subitems

