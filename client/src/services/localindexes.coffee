###
Local in memory indexes drive full text search and tagging.
###
define ['angular',
    'lunr',
    'lodash'
    'cs!./root'], (angular, lunr, _, root) ->
        root.factory 'LocalIndexes', ->
            #full text index for searchacross items
            fullTextIndex = lunr ->
                @field 'what', 8
                @field 'subs', 8
                @field 'who', 4
                @field 'tags', 2
                @field 'comments', 1
                @ref 'id'
            fullTextIndex.addToIndex = (item) ->
                #using clone as the deep visitor
                subtask_accumulator = []
                _.cloneDeep item.subitems, (x) ->
                    if x?.what
                        subtask_accumulator.push x.what
                    undefined
                fullTextIndex.update
                    id: item.id or ''
                    what: item.what or ''
                    subs: subtask_accumulator.join ' '
                    who: _.keys(item.links).join ' '
                    tags: (_.keys(item.tags).join ' ') or ''
                    comments: _.pluck(item?.discussion?.comments, 'what').join ' '
            links = {}
            updateLinks = (items) ->
                links = {}
                for id, item of items
                    for link, v of (item.links or {})
                        if links[link]
                            link[link] += 1
                        else
                            links[link] = 1
            tags = {}
            updateTags = (items) ->
                tags = {}
                for id, item of items
                    for tag, v of (item.tags or {})
                        if not item.done
                            if tags[tag]
                                tags[tag] += 1
                            else
                                tags[tag] = 1
                        else
                            tags[tag] = 0
            do ->
                update: (item, items) ->
                    #indexing to drive the tags, autocomplete, and screens
                    fullTextIndex.addToIndex item
                    updateLinks items
                    updateTags items
                delete: (item, items) ->
                    fullTextIndex.remove
                        id: item.id
                    updateLinks items
                    updateTags items
                tagSignature: ->
                    _.keys(tags).join ''
                tagCount: (tag) ->
                    tags[tag]
                tags: ->
                    _.sortBy _.keys(tags), (tag) -> -1 * tags[tag]
                linkSignature: ->
                    _.keys(links).join ''
                links: (match) ->
                    _.sortBy _.keys(links), (link) -> -1 * links[link]
                fullTextSearch: (query) ->
                    fullTextIndex.search(query)
