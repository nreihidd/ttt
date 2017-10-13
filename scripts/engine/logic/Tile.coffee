declare "Tile", class Tile
    defaultCollisionSet = {left: true, right: true, top: true, bottom: true}
    defaultEdgeTable = {
        left:   { "16": [[0, 16]] }
        right:  { "0":  [[0, 16]] }
        bottom: { "16": [[0, 16]] }
        top:    { "0":  [[0, 16]] }
    }
    @LOCAL_BOUNDS =
        left: 0
        right: 16
        bottom: 0
        top: 16
    
    constructor: (data, tileData) ->
        @_heightMap = undefined
        
        this[0] = data[0]
        this[1] = data[1]
        @flags  = data[2]
        @rotationData = Tile.rotationTable[@flags & 0x7]
        
        @rgba = [this[0], this[1], data[2], 255]
        
        if tileData?.collides
            @collisionSet = Tile.parseCollisionSet(tileData.collides, @rotationData)
        else
            @collisionSet = defaultCollisionSet
        if tileData?.height
            @_heightMap = Tile.parseHeightMap(tileData.height)
            @edgeTable = EdgeTable.createFromHeightMap(@_heightMap)
            @edgeTable = EdgeTable.rotateTable(@edgeTable, @rotationData)
            for side in Direction.directions
                if not (Direction.opposite[side] of @collisionSet)
                    @edgeTable[side] = {}
        else
            @edgeTable = defaultEdgeTable
            
    toCode: ->
        return this[0] + ',' + this[1] + ',' + @flags

    height: (x, reversed) ->
        if not @_heightMap
            return Level.TILE_SIZE
        if reversed
            return @_heightMap[Level.TILE_SIZE - (x % Level.TILE_SIZE) - 1]
        return @_heightMap[x % Level.TILE_SIZE]

    @rotationTable =
        0: {box: 'trbl', reversed: false, yreversed: false, restore: 0}
        1: {box: 'rblt', reversed: true,  yreversed: false, restore: 3}
        2: {box: 'bltr', reversed: true,  yreversed: true,  restore: 2}
        3: {box: 'ltrb', reversed: false, yreversed: true,  restore: 1}
        4: {box: 'brtl', reversed: false, yreversed: true,  restore: 4}
        5: {box: 'rtlb', reversed: false, yreversed: false, restore: 5}
        6: {box: 'tlbr', reversed: true,  yreversed: false, restore: 6}
        7: {box: 'lbrt', reversed: true,  yreversed: true,  restore: 7}
    (=>
        directionChars = {'t': 'top', 'r': 'right', 'b': 'bottom', 'l': 'left'}
        for flags of @rotationTable
            # console.log @rotTable[flags].box[2] == @rotTable[flags].bottom[0]
            entry = @rotationTable[flags]
            entry.top    = directionChars[entry.box[0]]
            entry.right  = directionChars[entry.box[1]]
            entry.bottom = directionChars[entry.box[2]]
            entry.left   = directionChars[entry.box[3]]
            entry.flags  = flags
            entry.inverse = @rotationTable[entry.restore]
    )()
        
    collidesSide: (side) ->
        return side of @collisionSet
        
    @parseCollisionSet = (str, rotData) ->
        obj = {}
        arr = str.split(/\s+|\s*,\s*/)
        for side in arr
            obj[rotData[side]] = true
        return obj
        
    @parseHeightMap = (str) ->
        if str.length < Level.TILE_SIZE
            console.log("WARNING: height map not long enough: " + data.height)
        result = []
        for char in str
            result.push(Tile.CHAR_HEIGHT[char])
        return result

    @CHAR_HEIGHT = ( ->
        str = "-0123456789ABCDEF"
        obj = {}
        for char, index in str
            obj[char] = index
        return obj
    )()
