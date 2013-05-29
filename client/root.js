//require would need to be configured separately, just FYI
require([
    'less!root',
    'angular',
    'cs!src/app',
], function (angular, less) {
    console.log("Root starting", arguments);
});
