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
define [], ->
    inverted =
        ###
        Create a new index, this tracks a single set of postings.
        ###
        index: (pipeline, keyFunction) ->
            #here is our 'private data'
            #here is the actual data structure for the index
            documents = {}
            #and track posting, being in memory make this easy to allow updating
            documentTerms = {}
            #and the inverted index itself
            termPostingLists = {}
            #big empty index awaits
            clear = ->
                termPostingLists = {}
                documentTerms = {}
            #This is the key function, making a posting and store it in the index
            postToIndex = (key, document, term, posting) ->
                #for the postings, this is the actual document itself, by reference
                #this is taking advantage of the face that we are in memory indexing
                #read objects
                documents[key] = document
                postTo = (termPostingLists[term] = termPostingLists[term] or {})
                postTo[key] = posting or true
                documentTerms[key] = documentTerms[key] or {}
                documentTerms[key][term] = posting or true
            #clear out a document and its postings
            unpostFromIndex = (key, document) ->
                for term, posting of (documentTerms[key] or {})
                    delete termPostingLists[term][key]
                    if not _.keys(termPostingLists[term]).length
                        delete termPostingLists[term]
                delete documents[key]
                delete documentTerms[key]
                document
            #this is the tokenization pipeline, starting with a document and then
            #ending up with postings
            tokenize = (key, document, perTermAction) ->
                #this is the 'last stage' where we go to the per term action
                #passed in by the index itself, so all pipelines get one more stage
                #then specified by the user
                callback = (term, posting) ->
                    perTermAction key, document, term, posting
                #building in reverse, making the links in the pipeline
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
                if document
                    key = keyFunction document
                    if key
                        unpostFromIndex key, document
                        tokenize key, document, postToIndex
            remove: (document) ->
                if document
                    key = keyFunction document
                    if key
                        unpostFromIndex key, document
            terms: ->
                _.keys(termPostingLists).sort()
            revision: ->
                md5(Object.keys(termPostingLists).join(''))
            search: (query, filter) ->
                query = query or {}
                filter = filter or -> true
                #given an object, parse it just like it was a document, but instead
                #it is a query
                candidate_sets = []
                bufferQuery = (key, document, term) ->
                    candidate_sets.push termPostingLists?[term] or []
                tokenize null, query, bufferQuery
                first_set = candidate_sets.shift()
                for set in candidate_sets
                    first_set = _.pick(first_set, _.keys(set))
                #and the very handy ability to tack on any old logical predicate
                #as a post processing filter
                _.filter((_.keys(first_set).map (x) -> documents[x]), filter)
