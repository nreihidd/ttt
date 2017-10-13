declare class LevelTileset
    @stringToTileData = (str) ->
        if matched = /([0-9]+),([0-9]+),([0-9]+)/.exec(str)
            return [parseInt(matched[1]), parseInt(matched[2]), parseInt(matched[3])]
        return null
        
    @tileDataToString = (data) ->
        return data[0] + ',' + data[1] + ',' + data[2]
    @tilePosToString = (data) ->
        return data[0] + ',' + data[1]
        
    constructor: (@image, @tiles, @url) ->
        @_tileTypes = {}
        @_tileData  = {}
    
    getTileType: (rcf) ->
        if rcf is null
            return null
        str = LevelTileset.tileDataToString(rcf)
        if not (str of @_tileTypes)
            @_tileTypes[str] = new Tile(rcf, @tiles[LevelTileset.tilePosToString(rcf)])
        return @_tileTypes[str]
        
    @load = (url, callback) ->
        loadJSON url, (tilesetData, status) ->
            if tilesetData
                callback(new LevelTileset(tilesetData.image, tilesetData.tiles, url), 'success')
            else
                callback(null, status)
                
        