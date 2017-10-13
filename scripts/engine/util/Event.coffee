window.when = (obj, callback) ->
    onFired = (index) ->
        if fired[index]
            return
        fired[index] = true
        count += 1
        if count is obj.length
            callback()
    
    if isArray(obj)
        count = 0
        fired = {}
        for l, i in obj
            l.listen(onFired.bind(null, i))
    else
        obj.listen callback

declare class Event
    constructor: (repeating) ->
        if typeof(repeating) is 'undefined'
            repeating = false
        @_repeating = repeating
        if not @_repeating
            @_fired = false
        @_onFire = {}
        @_nextId = 1
        @done = false
        
    fire: ->
        onFire = copyObject @_onFire
        
        if not @_repeating
            @_fired = true
            @_onFire = {}
            @done = true
        
        for id of onFire
            result = onFire[id].apply null, arguments

    listen: (callback) ->
        if @_fired
            callback()
            return 0
        else
            @_onFire[@_nextId] = callback
            return @_nextId++
            
    chain: (other) ->
        other.listen @fire.bind(this)

    forget: (id) ->
        delete @_onFire[id]
    
    @when = window.when
