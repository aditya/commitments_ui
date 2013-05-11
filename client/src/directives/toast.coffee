#Pop up toast, packed into a directive
define ['angular',
    'cs!src/readonly'], (angular) ->
    module = angular.module('readonly')
        .directive('toaster', ['User', (user) ->
            restrict: 'A'
            scope: true
            link: ($scope, element, attrs, ngModel) ->
                element.addClass 'toaster'
                lastToast = null
                element.find('.close').on 'click', ->
                    $scope.$apply ->
                        $scope.notification = null
                $scope.$on 'notification', (event, message) ->
                    if user.preferences.notifications
                        #there is already a panel up, double showing would be
                        #disturbing
                    else
                        $scope.notification = message
        ])
