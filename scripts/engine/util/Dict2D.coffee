

declare class Dict2D
    constructor: ->
        @root = {}
        
    has: (x, y) ->
        if not (x of @root)
            return false
        return y of @root[x]
        
    set: (x, y, val) ->
        if not (x of @root)
            @root[x] = {}
        @root[x][y] = val
        
    get: (x, y) ->
        if x of @root
            return @root[x][y]
        return undefined
        
    remove: (x, y) ->
        if x of @root
            delete @root[x][y]

    forEach: (func) ->
        for x, sub of @root
            for y, val of sub
                func(x, y, val)
