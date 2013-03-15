"use strict";

require.config({
    paths: {
        md5: 'lib/md5',
        jquery: 'lib/jquery',
        lodash: 'lib/lodash',
        markdown: 'lib/markdown',
        moment: 'lib/moment',
        angular: 'lib/angular/angular',
        'coffee-script': 'lib/coffee-script',
        cs: 'lib/require-cs',
        bootstrap: 'lib/bootstrap/js/bootstrap',
        tagbar: 'src/widgets/tagbar',
        calendar: 'src/widgets/calendar',
        widget: 'src/widgets/widget',
        sortable: 'src/widgets/sortable',
        mouse: 'src/widgets/mouse',
        less: 'lib/less',
        lunr: 'lib/lunr',
        codemirror: 'lib/codemirror/lib/codemirror',
        codemirrormarkdown: 'lib/codemirror/mode/markdown/markdown',
    },
    shim: {
        //export this, allows plug ins to hook on
        'jquery': {
            exports: 'jQuery'
        },
        'md5': {
            exports: 'md5'
        },
        'markdown': {
            exports: 'markdown'
        },
        //export angular, but make sure jquery is up so we don't get stuck
        //with jqlite!
        'angular': {
            deps: ['jquery'],
            exports: 'angular'
        },
        'bootstrap': {
            deps: ['jquery']
        },
        'mouse': {
            deps: ['jquery', 'widget']
        },
        'widget': {
            deps: ['jquery']
        },
        'sortable': {
            deps: ['jquery', 'mouse']
        },
        'calendar': {
            deps: ['jquery']
        },
        'tagbar': {
            deps: ['jquery']
        },
        'codemirror': {
            exports: 'CodeMirror',
            init: function () {
                require(['codemirrormarkdown']);
            }
        },
        'lunr': {
            exports: 'lunr'
        },
    },
});

require([
    'angular',
    'less',
    'cs!src/app'
], function (angular, less) {
    console.log("Root starting", arguments);
});
