#=========================================================
# Sprite Sheet

declare class SpriteSheet
    constructor: (@url) ->
        @events = 
            ready: new Event false
        
        @id = url
        @tileSheet = null
        
        queryJSON url, (data) =>
            @animations = data.animations
            @tileSheet = new TileSheet(data.url, [data.spriteWidth, data.spriteHeight])
            @events.ready.chain @tileSheet.events.ready

    getBounds: (row, col) ->
        if @events.ready.done
            return @tileSheet.getBounds row, col
        return Texture.FULL_BOUNDS

    bind: ->
        if @tileSheet
            @tileSheet.bind()

    @load = createCache
        key: (url) -> return url
        create: (url) -> return new SpriteSheet(url)