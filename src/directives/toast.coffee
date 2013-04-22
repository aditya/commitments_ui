#Pop up toast, packed into a directive
define ['angular',
    'bootstrap-notify',
    'cs!src/readonly'], (angular) ->
    module = angular.module('readonly')
        .directive('toaster', ['User', (user) ->
            restrict: 'A'
            link: ($scope, element, attrs, ngModel) ->
                $scope.$on 'notification', (event, message) ->
                    if user.preferences.notifications
                        #there is already a panel up, double showing would be
                        #disturbing
                    else
                        element.notify(
                            message: message.data.message
                            type: 'info'
                        ).show()
        ])
