###
This is a inverted index, allowing you to index and query JavaScript objects
in memory, and in real time. It is inspired by Xapian and Lucene, but implemented
in CoffeeScript with a functional rather than OO flair.

You can use it for full text search, faceting, and filtering.

# Definitions #

## Index ##
The index is the main data structure, it is composed of *documents* and *postings*.
You interact with the index by:

* `add`
* `remove`
* `search`
* `terms`
* `clear`

## Document ##
Documents are any valid JavaScript object. You `add` them to an *index*, which
will `tokenize` them into a series of *terms*.

A document can be supplied with a `key` function, which serves to identify a
unique document. This allows re-indexing. If not supplied, a document is identified
by its JavaScript reference.

## Term ##
Any JavaScript value can be a term. This allow you to index and search by more
than just strings. And it is important to note that a term is itself a document.

A term can have additional metadata:

* field: used to segment an index
* position: indicating an offset into the document for positional queries


## Posting ##
A posting is an associated of a *term*, with a
*document*. The document can then be retreived via `search` by the *term*.

## Tokenize ##
You can tokenize a document in many ways, but they all amount to taking an initial
document, subjecting it to a tokenization function, then calling back each time
a term is generated. These functions can be arranged in pipelines, allowing terms
to be further tokenized, until a final series of terms associated with a document
is complete.

Tokenization is done by way of functions, specifically a function generating
function to allow you a chance to 'set up' with any contextual or shared data.
The basic form looks like this:

tokenizer = (context) ->
    (document, callback) ->
        #your logic here, making any terms you see fit
        callback(term)

###


###
Create a new index.
###
@inverted = (context, pipelines) ->
    #here is our 'private data'
    #here is the actual data structure for the index
    perFieldPostings = {}
    #given our pipelines, initialize them to *this* index with the passed context
    initializedPipelines = {}
    clear = ->
        for field, pipeline of pipelines
            #under each field, we'll need storage for each term
            perFieldPostings[field] = {}
            #initialize the pipelines in this context, making the actual functions
            #that do the parsing and call back
            initializedPipelines[field] = pipeline.map ((stage) -> stage(context)), context
    #This is the key function, making a posting and store it in the index
    post = (document, field, term) ->
        console.log 'post', field, term
        perFieldPostings[field][term] = perFieldPostings[field][term] or []
        perFieldPostings[field][term].push document
    #this is the tokenization pipeline, starting with a document and then
    #ending up with postings
    tokenize = (document, perTermAction) ->
        for field, pipeline of initializedPipelines
            callback = (term) ->
                perTermAction document, field, term
            #building in reverse, so the last stage points to `post`
            for stage in pipeline[..].reverse()
                #capture the 'next' stage in a closure callback
                next = (callback, stage) ->
                    (term) ->
                        stage term, callback
                callback = next callback, stage
            #use the document as the first term to what is now the head of
            #the callback chain
            callback document
    #all set
    do clear
    #and here are the methods exposed by an index
    clear: clear
    add: (document) ->
        console.log 'add', document
        tokenize document, post
    remove: (document) ->
        console.log 'remove', document
    terms: (field) ->
        ret = []
        for term, postings of perFieldPostings[field]
            ret.push term
        ret
    search: (query) ->
        #given an object, parse it just like it was a document, but instead
        #it is a query
        ret = []
        bufferQuery = (document, field, term) ->
            console.log 'query', document, field, term
            ret = perFieldPostings?[field]?[term]
        tokenize query, bufferQuery
        ret
