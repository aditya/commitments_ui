#IMPORTANT: this needs to be the last coffeescript script

##Watch for changes, this is a client side hot reload system
if less
    less.watch()
    console.log('hot reloading less css')
#start the application here, manually to allow for the fact that the
#coffeescript is asynchronously compiled
angular.bootstrap document, ['Root']
