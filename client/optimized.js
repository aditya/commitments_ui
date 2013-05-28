//This is the server based requirejs optimization configuration
module.exports = {
  logLevel: 0,
  baseUrl: './',
  optimize: 'none',
  optimizeCss: 'none',
  name: 'root',
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
    cs: 'lib/cs',
    bootstrap: 'lib/bootstrap/js/bootstrap',
    tagbar: 'src/widgets/tagbar',
    less: 'lib/less',
    lunr: 'lib/lunr',
    mousetrap: 'lib/mousetrap',
    codemirror: 'lib/codemirror/lib/codemirror',
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
        require(['lib/codemirror/mode/markdown/markdown']);
      }
    },
    'lunr': {
      exports: 'lunr'
    },
  },
  stubModules: ['cs'],
}
