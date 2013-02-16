#Watch for changes, this is a client side hot reload system
poll = 1000
if less
    less.watch()
    console.log('hot reloading less css')

#hot reload of coffeescript
lastReload = {}

load = (url, callback) ->
    xhr = if window.ActiveXObject
        new window.ActiveXObject('Microsoft.XMLHTTP')
    else
        new XMLHttpRequest()
    xhr.open 'GET', url, true
    xhr.setRequestHeader 'Accept', 'text/coffeescript'
    xhr.onreadystatechange = ->
        if xhr.readyState is 4
            if xhr.status in [0, 200]
                callback(url, xhr.responseText, xhr.getResponseHeader('Last-Modified'))
    xhr.send null

compile = (url, source, lastModified) ->
    if lastReload[url] isnt lastModified
        lastReload[url] = lastModified
        console.log "recompiling #{url}"
        CoffeeScript.run source


watchTimer =
    setInterval ->
        for script in document.getElementsByTagName('script')
            if script?.type is 'text/coffeescript' and script?.src
                if /watch\.coffee$/.test script.src
                    #self reload! pass this
                else
                    load script.src, compile
    , poll

#trap angular module definition, this will drive the hot loading graph
trap = angular.injector(['ng'])

trap.invoke ($rootScope, $compile, $document, $q) ->
    #here is the wrap part of the module load trap
    originalAngularModule = angular.module
    #and now we trap all of our modules to hot restart the application
    angular.module = (name, requires, config) ->
        ret = originalAngularModule name, requires, config
        #a module has changed, restart the application
        setTimeout ->
            angular.bootstrap document, ['Root']
        ret

#initial start of the application
angular.bootstrap document, ['Root']
