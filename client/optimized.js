//This is the server based requirejs optimization configuration
module.exports = {
    logLevel: 0,
    baseUrl: './',
    optimize: 'none',
    findNestedDependencies: true,
    name: 'root',
    pragmasOnSave: {
        //Just an example
        excludeCoffeeScript: true
    },
    deps: ['css'],
    stubModules: ['cs', 'coffee-script', 'lessc' ],
    paths: {
        md5: 'lib/md5',
        store: 'lib/store',
        jquery: 'lib/jquery',
        jqueryui: 'lib/jqueryui',
        lodash: 'lib/lodash',
        socketio: 'lib/socket.io',
        marked: 'lib/marked',
        moment: 'lib/moment',
        grid: 'lib/grid-a-licious',
        angular: 'lib/angular/angular',
        'coffee-script': 'lib/coffee-script',
        cs: 'lib/require/cs',
        less: 'lib/require/less',
        text: 'lib/require/text',
        css: 'lib/require/css',
        'less-builder': 'lib/require/less-builder',
        'css-builder': 'lib/require/css-builder',
        'normalize': 'lib/require/normalize',
        'lessc-server': 'lib/require/lessc-server',
        'lessc': 'lib/require/lessc',
        bootstrap: 'lib/bootstrap/js/bootstrap',
        tagbar: 'src/widgets/tagbar',
        lunr: 'lib/lunr',
        mousetrap: 'lib/mousetrap',
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
        'jqueryui': {
            deps: ['jquery']
        },
        'tagbar': {
            deps: ['jquery']
        },
        'codemirror': {
            exports: 'CodeMirror'
        },
        'codemirrormarkdown': {
            deps: ['codemirror']
        },
        'lunr': {
            exports: 'lunr'
        },
    },
}
