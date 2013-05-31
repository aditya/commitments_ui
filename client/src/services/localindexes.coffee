###
Local in memory indexes drive full text search and tagging.
###
define ['angular',
    'cs!src/inverted/inverted',
    'lunr',
    'lodash'
    'cs!./root'], (angular, inverted, lunr, _, root) ->
        root.factory 'LocalIndexes', ->
            #parsing functions to keep track of all links and tags
            parseTags = (document, callback) ->
                for tag, v of (document?.tags or {})
                    callback tag
            #inverted indexing for tags
            tagIndex = inverted.index [parseTags], (x) -> x.id
            #full text index for searchacross items
            fullTextIndex = lunr ->
                @field 'what', 8
                @field 'who', 4
                @field 'tags', 2
                @field 'comments', 1
                @ref 'id'
            fullTextIndex.addToIndex = (item) ->
                fullTextIndex.update
                    id: item.id or ''
                    what: item.what or ''
                    who: _.keys(item.links).join ' '
                    tags: (_.keys(item.tags).join ' ') or ''
                    comments: (_.map(
                        item?.discussion?.comments,
                        (x) -> x.what).join ' ') or ''
            links = {}
            update_links = (items) ->
                links = {}
                for id, item of items
                    for link, v of (item.links or {})
                        links[link] = true
            do ->
                update: (item, items) ->
                    #indexing to drive the tags, autocomplete, and screens
                    tagIndex.add item
                    fullTextIndex.addToIndex item
                    update_links items
                delete: (item, items) ->
                    tagIndex.remove item
                    fullTextIndex.remove
                        id: item.id
                    update_links items
                tags: ->
                    tagIndex.terms()
                tagSignature: ->
                    tagIndex.terms().join('')
                linkSignature: ->
                    _.keys(links).join ''
                links: (filter) ->
                    _.select _.keys(links), filter
                itemsByTag: (tags, filter) ->
                    if _.isString tags
                        by_tag = {tags: {}}
                        by_tag.tags[tags] = 1
                    else
                        by_tag = tags
                    tagIndex.search(by_tag, filter)
                fullTextSearch: (query) ->
                    fullTextIndex.search(query)
