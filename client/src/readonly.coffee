define [
    'bootstrap',
    ], () ->
    AUTOHIDE_DELAY = 3000
    ANIMATION_SPEED = 100
    KEY_DELAY = 300
    module = angular.module('readonly', [])
        .directive('flashMessage', [() ->
            restrict: 'A'
            link: ($scope, element, attrs, ngModel) ->
                $scope.$watch attrs.flashMessage, (message) ->
                    element.addClass 'flashmessage'
                    messageLayout = $("<span>#{message}</span>")
                    element.children().remove()
                    element.append messageLayout
                    if message
                        element.show ANIMATION_SPEED, ->
                            messageLayout.addClass 'animated flash'
                    else
                        element.hide ANIMATION_SPEED
        ])
        .directive('gravatar', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'gravatar'
                size = attrs.size or 50
                icon = angular.element("<img></img>")
                element.append(icon)
                ngModel.$render = ->
                    if not ngModel.$viewValue
                        ngModel.$setViewValue($scope.$eval(attrs.default))
                    hash = md5((ngModel.$viewValue or '').toLowerCase())
                    icon.attr 'src', "http://www.gravatar.com/avatar/#{hash}.jpg?d=mm&s=#{size}"
        ])
        .directive('username', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'username'
                element.append "<i class='icon-user'/>"
                display = angular.element "<span/>"
                element.append display
                ngModel.$render = ->
                    if ngModel.$viewValue
                        display.text ngModel.$viewValue
        ])
        .directive('postdate', [() ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'postdate'
                element.append "<i class='icon-time'/>"
                display = angular.element "<span/>"
                element.append display
                ngModel.$render = ->
                    if ngModel.$viewValue
                        display.text moment(ngModel.$viewValue).fromNow()
        ])
        .directive('animatedHide', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                #counter is in here so an initial hide isn't animated, just hidden
                #so we'll only animate if it was visible on the first pass
                counter = 0
                $scope.$watch attrs.animatedHide, (hide) ->
                    if hide
                        if counter
                            uelement.hide(ANIMATION_SPEED)
                        else
                            element.hide()
                    else
                        element.show()
                    counter++
        ])
        .directive('animatedShow', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                #counter is in here so an initial hide isn't animated, just hidden
                #so we'll only animate if it was visible on the first pass
                counter = 0
                $scope.$watch attrs.animatedShow, (show) ->
                    if show
                        if counter
                            element.show(ANIMATION_SPEED)
                        else
                            element.show(0)
                    else
                        if counter
                            element.hide(ANIMATION_SPEED)
                        else
                            element.hide(0)
                    counter++
        ])
        .directive('animatedVisible', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $scope.$watch attrs.animatedVisible, (show) ->
                    if show
                        element.animate
                            opacity: 1
                        , ANIMATION_SPEED
                    else
                        element.animate
                            opacity: 0
                        , ANIMATION_SPEED
        ])
        .directive('activeIf', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $scope.$watch attrs.activeIf, (val) ->
                    if val
                        element.addClass 'active'
                    else
                        element.removeClass 'active'
        ])
        .directive('readonlyIf', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $scope.$watch attrs.readonlyIf, (val) ->
                    if val
                        element.addClass 'readonly'
                    else
                        element.removeClass 'readonly'
        ])
        .directive('delayed', ['$timeout', ($timeout) ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                going = null
                fire = ->
                    val = element.val()
                    $scope.$apply ->
                        $scope.$emit attrs.delayed, val
                element.on 'keyup', (event)->
                    if event.which is 27 #escape
                        element.val ''
                element.on 'keyup', _.debounce(fire, KEY_DELAY)
                element.on 'blur', ->
                    element.val ''
                    fire()
        ])
        .directive('action', ['$timeout', ($timeout) ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.addClass 'action'
                element.css 'cursor', 'pointer'
        ])
        .directive('eatClick', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.on 'click', (event) ->
                    event.preventDefault()
        ])
        .directive('help', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.addClass 'help'
                #capture the existing content, we'll use it later in a popup
                content = element.children()
                content.hide()
                twizzler = $('<span class="icon-question"></span>')
                element.append twizzler
                twizzler.tooltip
                    html: true
                    title: content.html()
                    placement: 'bottom'
                    delay:
                        show: ANIMATION_SPEED
                        hide: ANIMATION_SPEED
                twizzler.on 'click', (event)->
                    event.stopPropagation()
                    twizzler.tooltip('show')
        ])
        #a loading image, this just hides as soon as possible, meaning that
        #angular is on the air and running
        .directive('loading', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.hide()
        ])
