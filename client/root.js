//require would need to be configured separately, just FYI
require([
    'angular',
    'lessc',
    'jquery',
    'less!root',
    'cs!src/app',
], function (angular, less, $) {
    console.log("Root starting", arguments);
    //this is a dynamic stylesheet debug capability
    window.debugStyles = function() {
        $('style').remove();
        less.refresh();
        less.watch();
        console.log('watching styles');
    };
});
