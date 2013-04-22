"use strict";

require.config({
    paths: {
        md5: 'lib/md5',
        jquery: 'lib/jquery',
        jqueryui: 'lib/jqueryui',
        lodash: 'lib/lodash',
        socketio: 'lib/socket.io',
        markdown: 'lib/markdown',
        moment: 'lib/moment',
        angular: 'lib/angular/angular',
        'coffee-script': 'lib/coffee-script',
        cs: 'lib/require-cs',
        bootstrap: 'lib/bootstrap/js/bootstrap',
        'bootstrap-notify': 'lib/bootstrap-notify/bootstrap-notify',
        tagbar: 'src/widgets/tagbar',
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
        'bootstrap-notify': {
            deps: ['jquery']
        },
        'bootstrap': {
            deps: ['jquery']
        },
        'jqueryui': {
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
