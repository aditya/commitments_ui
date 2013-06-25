###
Comment service, this provides data and needed actions.
###
define ['angular'
    'cs!./root'], (angular, root) ->
        root.factory 'Comment', (User) ->
            service =
                newcomment: (comment) ->
                    comment.who = comment.who or User.email
                    comment.when = comment.when or Date.now()
                    comment.id = comment.id or md5("#{Date.now()}")
