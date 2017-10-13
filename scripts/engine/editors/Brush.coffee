#=========================================================
# Brush

# TODO: Add horizontal/vertical line brushes

declare class Brush
    @MAX_SIZE = 20
    
    constructor: ->
        @shape = 'square'
        @size  = 1
        @mode  = 'none'
        @position = [0, 0]
        @tile = [0, 0, 0]
        @visible = false
        @smooth = false
        
        @observables =
            tile: new Observable(@tile)
        
    setTile: (r, c, flags) ->
        @tile[0] = r
        @tile[1] = c
        @tile[2] = flags
        @observables.tile.update(@tile)
        
    _updatePosition: ->
        if @size % 2 is 1
            [@col, @row] = SpaceConversion.Game.GameLevelTile(@_x, @_y)
            if @smooth
                @position = [@_x - Level.TILE_SIZE / 2, @_y - Level.TILE_SIZE / 2]
            else
                @position = SpaceConversion.GameLevelTile.Game(@col, @row)
        else
            [@col, @row] = SpaceConversion.Game.GameLevelTile(@_x - Level.TILE_SIZE / 2, @_y - Level.TILE_SIZE / 2)
            if @smooth
                @position = [@_x, @_y]
            else
                @position = SpaceConversion.GameLevelTile.Game(@col + 1, @row + 1)
        
    setPosition: (x, y) ->
        @_x = x
        @_y = y
        @_updatePosition()
        
    countTiles: ->
        count = 0
        @forEachTile =>
            count += 1
            return
        return count
        
    forEachTile: (callback) ->
        if @size % 2 is 1
            extraRadius = Math.floor((@size - 1) / 2)
            if @shape is 'square'
                for r in [(@row - extraRadius)..(@row + extraRadius)] by 1
                    for c in [(@col - extraRadius)..(@col + extraRadius)] by 1
                        callback(r, c)
            if @shape is 'circle'
                for r in [(@row - extraRadius)..(@row + extraRadius)] by 1
                    for c in [(@col - extraRadius)..(@col + extraRadius)] by 1
                        dr = @row - r
                        dc = @col - c
                        if dr * dr + dc * dc <= extraRadius * extraRadius
                            callback(r, c)
        else
            extraRadius = @size / 2
            if @shape is 'square'
                for r in [(@row - extraRadius + 1)..(@row + extraRadius)] by 1
                    for c in [(@col - extraRadius + 1)..(@col + extraRadius)] by 1
                        callback(r, c)
            if @shape is 'circle'
                for r in [(@row - extraRadius + 1)..(@row + extraRadius)] by 1
                    for c in [(@col - extraRadius + 1)..(@col + extraRadius)] by 1
                        dr = @row - r + 0.5
                        dc = @col - c + 0.5
                        if dr * dr + dc * dc <= (extraRadius) * (extraRadius)
                            callback(r, c)

    setSize: (size) ->
        @size = clamp(1, size, Brush.MAX_SIZE)
        @_updatePosition()
        
    isVisible: ->
        return @mode isnt 'none' and @visible
        