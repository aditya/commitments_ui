//require would need to be configured separately, just FYI
require([
    'angular',
    'less!root',
    'cs!src/app',
], function (angular, less, $) {
    console.log("Root starting", arguments);
});
