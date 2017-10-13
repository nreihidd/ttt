#=========================================================
# Tile Sheet

declare class TileSheet
    constructor: (url, size) ->
        @events =
            ready: new Event false

        @texture = Texture.load(url)
        @tileWidth = size[0]
        @tileHeight = size[1]
        
        @texture.events.ready.listen =>
            @tileStartX = 1.0 / @texture.width
            @tileStartY = 1.0 / @texture.height
            @tileScaleX = (@tileWidth + 1.0) / @texture.width
            @tileScaleY = (@tileHeight + 1.0) / @texture.height
            @tileTextureWidth = (@tileWidth * 1.0) / @texture.width
            @tileTextureHeight = (@tileHeight * 1.0) / @texture.height
            @events.ready.fire()

    getBounds: (row, col) ->
        if not @events.ready.done
            return Texture.FULL_BOUNDS

        left = col * @tileScaleX + @tileStartX
        bottom = row * @tileScaleY + @tileStartY
        right = left + @tileTextureWidth
        top = bottom + @tileTextureHeight
            
        return (
            'left': left
            'top': bottom
            'right': right
            'bottom': top
        )

    bind: ->
        @texture.bind()
