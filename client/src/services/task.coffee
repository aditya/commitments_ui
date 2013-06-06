###
Task service, this provides the needed action verbs in one place so that
it is a bit easier to see.
###
define ['angular',
    'lodash',
    'cs!./root'], (angular, _, root) ->
        root.factory 'Task', ($timeout, $rootScope, User) ->
            service =
                new: (task) ->
                    if not task.who
                        task.who = User.email
                    if not task.id
                        task.id = md5("#{Date.now()}")
                    if not task.when
                        task.when = Date.now()
                    service.update task
                update: (task) ->
                    $rootScope.$broadcast 'updateitem', task
                delete: (task) ->
                    $rootScope.$broadcast 'deleteitem', task
                accepttask: (task) ->
                    task.links[User.email] = Date.now()
                    task.accept[User.email] = Date.now()
                    delete task.reject[User.email]
                    service.update task
                rejecttask: (task) ->
                    task.reject[User.email] = Date.now()
                    delete task.links[User.email]
                    delete task.accept[User.email]
                    service.update task
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
                deletetask: (task) ->
                    #you really only truly delete tasks you create, otherwise
                    #it is the same thing as rejecting
                    console.log task, 's'
                    if task.who is User.email
                        #real delete
                        service.delete task
                    else
                        service.rejecttask task
