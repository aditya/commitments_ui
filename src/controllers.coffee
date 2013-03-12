define ['angular',
    'lodash',
    'cs!src/inverted/inverted',
    'cs!src/services',
    'cs!src/editable',
    'cs!src/readonly'], (angular, _, inverted) ->
    module = angular.module('Root', ['RootServices', 'editable', 'readonly'])
        .controller 'Desktop', ($scope, Database, StackRank, Authentication, Preferences) ->
            $scope.tagNamespaceSeparators = [':', '/']
            $scope.stackRank = StackRank()
            $scope.database = Database()
            $scope.user = Authentication.user()
            $scope.tags = Preferences.tags()
            $scope.messages =
                info: 'Alerts & Messages'
                count: 0
            $scope.selectBox = (box) ->
                $scope.selected = box
                $scope.selected.items = $scope.stackRank.sort(
                    box.filter(),
                    $scope.user.email,
                    box.tag)
            $scope.poke = (item) ->
                console.log 'poking', item
            $scope.newItem = (item) ->
                $scope.database.items.push item
                $scope.lastUpdatedItem = item
            $scope.updateItem = (item) ->
                $scope.lastUpdatedItem = item
            $scope.placeholderItem = (item) ->
                ($scope.selected.stamp or ->)(item)
            $scope.deleteItem  = (item) ->
                list = $scope.database.items
                foundAt = list.indexOf(item)
                if foundAt >= 0
                    list.splice(foundAt, 1)
                    $scope.lastDeletedItem = item
        .controller 'Toolbox', ($scope, $rootScope) ->
            #always have the todo and done boxes
            $scope.boxes = [
                title: 'Todo'
                tag: '*'
                filter: -> _.reject($scope.database.items, (x) -> x.done)
                hide: (x) -> x.done
            ,
                title: 'Done'
                tag: '*'
                filter: -> _.filter($scope.database.items, (x) -> x.done)
                hide: (x) -> not x.done
            ]
            #initial view selection
            $scope.selectBox $scope.boxes[0]
            #just pick out tags from a todo, these will be facets
            parseTags = (document, callback) ->
                for tag, v of (document?.tags or {})
                    callback tag
            tagIndex = $scope.tagIndex = inverted.index [parseTags], (x) -> x.id
            #any time the database changes, we need to build a whole new tag
            #index
            $scope.$watch 'database', (database) ->
                console.log 'reindexing'
                do tagIndex.clear
                for item in database.items
                    tagIndex.add item
                console.log 'reindexing complete'
            #watch the index for changes, and if you see them rebuild all the tags
            #so that we track the currently available facets
            $scope.$watch 'tagIndex.revision()', ->
                #tags currently on display, which may have been updated / ordered
                displayTags = {}
                for tag in $scope.tags
                    displayTags[tag.tag] = tag
                #dynamic tags from the index, these are current
                tags = {}
                for tagTerm in tagIndex.terms()
                    byTag = (tagTerm, filter) ->
                        () ->
                            by_tag = {tags: {}}
                            by_tag.tags[tagTerm] = 1
                            tagIndex.search(by_tag, filter)
                    stampWithTag = (tagTerm) ->
                        (item) ->
                            item.tags = item.tags or {}
                            item.tags[tagTerm] = Date.now()
                    dynamicTag =
                        title: tagTerm
                        tag: tagTerm
                        when: Date.now()
                    dynamicTagMethods =
                        hide: -> false
                        filter: byTag(tagTerm)
                        todoCount: byTag(tagTerm, (x) -> not x.done)
                        stamp: stampWithTag(tagTerm)
                    #make an object sandwich, overlaying the dynamic functions
                    #but only using the tag term as the base default, prefering
                    #what the user has updated
                    _.extend dynamicTag, displayTags[tagTerm] or {}, dynamicTagMethods
                    tags[tagTerm] = dynamicTag
                #at this point we have all the tags currently in the index
                #but with the 'saved' properties like sort order merged in
                $scope.tags = $scope.stackRank.sort(
                    _.values(tags),
                    $scope.user.email)
                $scope.stackRank.renumber($scope.tags, $scope.user.email)
            #peek at the model to see when it it time to add or remove an item
            $scope.$watch 'lastUpdatedItem', (item) ->
                tagIndex.add item
            , true
            $scope.$watch 'lastDeletedItem', (item) ->
                tagIndex.remove item
            , true
            #
        .controller 'Discussion', ($scope) ->
            null
        #accepting and rejecting tasks ias simply about stamping it with
        #your user identity, or removing yourself as a delegate
        .controller 'TaskAccept', ($scope, $timeout) ->
            $scope.accept = (item) ->
                item.accept[$scope.user.email] = Date.now()
            $scope.reject = (item) ->
                delete item.delegates[$scope.user.email]
                delete item.accept[$scope.user.email]
        .config ->
            null
        .run ->
            console.log 'starting application'
