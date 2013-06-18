define [
    'md5',
    'bootstrap',
    'mousetrap',
    'grid',
    ], (md5, __ignore__bootstrap__, mousetrap, grid) ->
    ANIMATION_SPEED = 100
    TOOLTIP_SPEED = 600
    KEY_DELAY = 300
    module = angular.module('readonly', [])
        .directive('flashMessage', [() ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
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
        .directive('default', ['$rootScope', ($rootScope) ->
            restrict: 'A'
            require: 'ngModel'
            priority: 1000
            link: ($scope, element, attrs, ngModel) ->
                $scope.$watch attrs.default, (value) ->
                    if not ngModel.$viewValue and value
                        ngModel.$setViewValue(value)
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
                    hash = md5((ngModel.$viewValue or '').toLowerCase())
                    icon.attr 'src', "http://www.gravatar.com/avatar/#{hash}.jpg?d=mm&s=#{size}"
                $scope.$watch attrs.ngModel, ->
                    ngModel.$render()
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
                    #always have a date value
                    if not ngModel.$viewValue
                        ngModel.$setViewValue Date.now()
                    display.text moment(ngModel.$viewValue).fromNow()
                $scope.$watch attrs.ngModel, ->
                    ngModel.$render()
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
                            element.hide(ANIMATION_SPEED)
                        else
                            #first hit, hide right away
                            element.hide()
                    else
                        element.show(ANIMATION_SPEED)
                    counter++
        ])
        .directive('animatedHideOn', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                #event driven animated hide
                for event in attrs.animatedHideOn.split(',')
                    event = event.trim()
                    $scope.$on event,  ->
                        element.hide(ANIMATION_SPEED)
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
                    element.removeClass 'animated'
                    if show
                        element.removeClass 'flipOutX'
                        element.addClass 'animated flipInX'
                    else
                        element.removeClass 'flipInX'
                        element.addClass 'animated flipOutX'
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
        .directive('delayed', ['$timeout', '$rootScope', ($timeout, $rootScope) ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                going = null
                fire = ->
                    val = element.val()
                    $scope.$apply ->
                        $rootScope.$broadcast attrs.delayed, val
                element.on 'keyup', (event)->
                    if event.which is 27 #escape
                        element.val ''
                element.on 'keyup', _.debounce(fire, KEY_DELAY)
                element.on 'blur', ->
                    element.val ''
                    fire()
        ])
        .directive('action', [ ->
            restrict: 'A'
            require: '^ngModel'
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'action'
                element.css 'cursor', 'pointer'
                #named event emission
                if attrs.action
                    element.on 'click', ->
                        console.log 'action', attrs.action, ngModel.$modelValue
                        $scope.$emit attrs.action, ngModel.$modelValue
        ])
        #This is low priority, so that an element can have click handlers, but
        #ultimately is a firewall to keep clicks from making it out of an element
        .directive('eatClick', [ ->
            restrict: 'A'
            priority: -1000
            link: ($scope, element) ->
                element.click (event) ->
                    event.stopPropagation()
        ])
        .directive('help', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.addClass 'help'
                element.hide()
                element.parent().parent().tooltip
                    trigger: 'hover'
                    html: true
                    title: element.html()
                    placement: 'bottom'
                    delay:
                        show: TOOLTIP_SPEED
                        hide: ANIMATION_SPEED
                element.parent().parent().on 'mousedown', ->
                    element.parent().parent().tooltip 'hide'
        ])
        .directive('tooltip', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $scope.$watch attrs.tooltip, (content) ->
                    if attrs.hotkey
                        hotkey = attrs.hotkey.split(',')[0]
                        content = "#{content}<br/>Hotkey: <em>#{hotkey}</em>"
                    if content
                        element.tooltip(
                            trigger: 'hover'
                            html: true
                            title: content
                            placement: 'bottom'
                            delay:
                                show: TOOLTIP_SPEED
                                hide: ANIMATION_SPEED
                        )
                        element.on 'mousedown', ->
                            element.tooltip 'hide'
        ])
        #a loading image, this just hides as soon as possible, meaning that
        #angular is on the air and running
        .directive('loading', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.hide()
        ])
        #a single hotkey binding
        .directive('clickable', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.css 'cursor', 'pointer'
        ])
        #a single hotkey binding
        .directive('hotkey', [ '$rootScope', ($rootScope) ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                key_name = attrs.hotkey.split(',')
                act = ->
                    console.log 'hotkey', key_name
                    $rootScope.$apply ->
                        for en in _.rest(key_name)
                            $rootScope.$broadcast en
                    false
                element.on 'click', act
                mousetrap.bind key_name[0], act
        ])
        #grid a licious grid
        .directive('grid', [ '$timeout', ($timeout) ->
            restrict: 'A'
            require: 'ngModel'
            link: ($scope, element, attrs) ->
                $timeout ->
                    element.gridalicious(
                        animate: false
                        selector: attrs.grid
                    )
        ])
        .directive('animatedFocus', [ ->
            restrict: 'A'
            link: ($scope, element) ->
                element.on 'focus', ->
                    element.addClass 'focused'
                element.on 'blur', ->
                    element.removeClass 'focused'
                element.on 'keydown', (event) ->
                    if event.which is 27 #escape
                        element.blur()
                        event.stopPropagation()
        ])
        #
        .directive('focusOn', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                $scope.$on attrs.focusOn, ->
                    element.focus()
        ])
        #
        .directive('readonlyHref', [ ->
            restrict: 'A'
            link: ($scope, element, attrs) ->
                element.attr 'href', $scope.$eval(attrs.readonlyHref)
                $scope.$on attrs.focusOn, ->
                    element.focus()
        ])
