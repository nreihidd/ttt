#=========================================================
# Level

declare class Level
    @TILE_SIZE = 16
    @FLAG_FLIP_VERTICAL = 4
    @FLAG_ROTATE_180    = 2
    @FLAG_ROTATE_90     = 1
    
    constructor: (levelJSONData, levelData, @tileset, @name) ->
        @events =
            edited:  new Event true

        @observables =
            size: new Observable(undefined)
            tileset: new Observable(undefined)
            backgroundColor: new Observable(undefined)
            
        @backgroundColor = levelJSONData.backgroundColor ? [1, 1, 1, 1]
        @entityDescriptions = levelJSONData.entities
        
        @tiles = [[]]
        rows = levelData.height
        cols = levelData.width
        data = levelData.data
        @setLevelSize(rows, cols)
        for i in [0...Math.min(rows, data.length)] by 1
            for j in [0...Math.min(cols, data[i].length)] by 1
                @tiles[i][j] = @tileset.getTileType(data[i][j])

        # @tiles = for i in [0...rows] by 1
        #     for j in [0...cols] by 1
        #        @tileset.getTileType(data[i][j])
                
        @observables.tileset.update(@tileset)
    
    forEachTile: (func) ->
        for row in [0...@tiles.length]
            for col in [0...@tiles[row].length]
                func(row, col, @tiles[row][col])

    setBackgroundColor: (color) ->
        @backgroundColor = color
        @observables.backgroundColor.update(@backgroundColor)
                
    setTileset: (tileset) ->
        if @tileset?.url is tileset.url
            return
        @tileset = tileset
        @tiles = for i in [0...@tiles.length] by 1
            for j in [0...@tiles[i].length] by 1
                if @tiles[i][j] isnt null
                    tile = @tiles[i][j]
                    @tileset.getTileType([tile[0], tile[1], tile.flags])
                else
                    null
        @observables.tileset.update(@tileset)
    setTilesetURL: (tilesetURL) ->
        LevelTileset.load tilesetURL, (tileset, status) =>
            if tileset
                @setTileset(tileset)

    getLevelSize: ->
        return [@tiles.length, @tiles[0].length]
        
    setLevelSize: (numRows, numCols) ->
        # First extend/truncate each row to match numCols
        for row in @tiles
            while row.length < numCols
                row.push(null)
            if row.length > numCols
                row.splice(numCols, row.length - numCols)
                
        # Now add/remove rows to match numRows
        while @tiles.length < numRows
            row = []
            while row.length < numCols
                row.push(null)
            @tiles.push(row)
        if @tiles.length > numRows
            @tiles.splice(numRows, @tiles.length - numRows)
        
        @size = [numCols * Level.TILE_SIZE, numRows * Level.TILE_SIZE]
        @bounds = {left: 0, bottom: 0, right: @size[0], top: @size[1]}
        @observables.size.update(@getLevelSize())
        
    getTile: (r, c) ->
        if r < 0 or r >= @tiles.length
            return null
        if c < 0 or c >= @tiles[r].length
            return null
        return @tiles[r][c]
        
    getTileType: (code) ->
        return @tileset.getTileType(code)
        
    setTile: (r, c, tileType) ->
        if r < 0 or c < 0 or r >= @tiles.length or c >= @tiles[r].length
            # console.log 'Adding tiles is not yet implemented'
            return
        @tiles[r][c] = tileType # @tileset.getTileType(code)
        @events.edited.fire(r, c)
        
    toJSON: ->
        return JSON.stringify({
            backgroundColor: @backgroundColor,
            tileset: @tileset.url,
            levelPNG: LevelMap.levelToBase64PNG(this),
            entities: Engine.entityManager.getEntityDescriptions()
        })

    @load = (name, callback) ->
        url = '/get-level?name=' + name
        
        loadJSON url, (levelJSONData, status) ->
            if not levelJSONData
                callback(null, "failed to retrieve #{url}: #{status}")
            else if levelJSONData.level and not levelJSONData.levelPNG
                callback(null, "outdated level format")
            else if not levelJSONData.levelPNG
                callback(null, "level missing levelPNG")
            else
                LevelTileset.load levelJSONData.tileset, (tileset, status) ->
                    if not tileset
                        callback(null, "failed to retrieve #{levelJSONData.tileset} for #{name}: #{status}")
                    else
                        LevelMap.pngToLevelData levelJSONData.levelPNG, (levelData) ->
                            level = new Level(levelJSONData, levelData, tileset, name)
                            callback(level, 'success')

    @create = (callback) ->
        LevelTileset.load "/levels/tilesets/outdoors-tileset.json", (tileset, status) ->
            if not tileset
                callback(null, "failed to retrieve default tileset: #{status}")
            else
                level = new Level({backgrounds: [], backgroundColor: [1, 1, 1, 1], entities: []}, {
                    width: 20,
                    height: 20,
                    data: [[]]
                }, tileset, "New-Level")
                # level.setLevelSize(20, 20)
                callback(level, 'success')
            