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
        'cs': 'lib/require-cs',
        bootstrap: 'lib/bootstrap/js/bootstrap',
        tagbar: 'src/widgets/tagbar',
        jqueryui: 'lib/jquery-ui',
        less: 'lib/less',
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
        //bootstrap defines tooltip, and so does jqueryui, so this dependency
        //makes sure bootstrap runs after and overwrites
        'bootstrap': {
            deps: ['jquery', 'jqueryui']
        },
        'tagbar': {
            deps: ['jquery']
        },
        'jqueryui': {
            deps: ['jquery']
        },
        'codemirror': {
            export: 'CodeMirror',
            init: function () {
                require(['codemirrormarkdown']);
            }
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
