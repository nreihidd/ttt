#=========================================================
# Tileset Editor -- Singleton

declare class TilesetEditor
    constructor: (@brush) ->
        
        $("#tileset-overview").mousedown(@_onOverviewClick.bind(this))
        @image = new Image()
        @numRows = 1
        @numCols = 1
        
        @overviewContext = $("#tileset-overview")[0].getContext('2d')
        @heightMapContext = $("#height-map")[0].getContext('2d')
        
        @setTileset({tiles: {}})
        
        Keyboard.registerHotkey Keyboard.KEYS.arrowLeft, =>
            @moveSelection(0, -1)
        Keyboard.registerHotkey Keyboard.KEYS.arrowRight, =>
            @moveSelection(0, 1)
        Keyboard.registerHotkey Keyboard.KEYS.arrowUp, =>
            @moveSelection(-1, 0)
        Keyboard.registerHotkey Keyboard.KEYS.arrowDown, =>
            @moveSelection(1, 0)

        # Observers
        @observers =
            levelTileset: new Observer (tileset) =>
                @setTileset(tileset)
            brushTile: new Observer (tile) =>
                @_onTileChanged(tile)
            level: new Observer (level) =>
                if level
                    @observers.levelTileset.observe(level.observables.tileset)
                else
                    @observers.levelTileset.forget()
        
        @observers.brushTile.observe(@brush.observables.tile)
        @observers.level.observe(Engine.observables.level)
        
    @TILE_PREVIEW_SIZE = 64

    setTileset: (tileset) ->
        if tileset.image
            @image.src = tileset.image
            @image.onload = =>
                [@numCols, @numRows] = SpaceConversion.TilesetOverview.Tileset(@image.width, @image.height)
                @_redrawOverview()
                @_onTileChanged(@tile)
        @tileset = tileset
        @setTile(0, 0)

    _redrawOverview: ->
        @overviewContext.canvas.width = @image.width
        @overviewContext.canvas.height = @image.height

        ctx = @overviewContext
        ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height)
        # see: https://bugzilla.mozilla.org/show_bug.cgi?id=574330
        # attempting to draw an image that hasn't loaded fully in firefox will throw an exception
        if @image.complete and @image.src
            ctx.drawImage(@image, 0, 0, @image.width, @image.height, 0, 0, @image.width, @image.height)
        
        ctx.strokeStyle = "rgba(255,0,255,1)"
        ctx.lineWidth = 1
        ctx.lineJoin = 'miter'
        
        ctx.beginPath()
        [r, c] = @tile
        [c, r] = SpaceConversion.Tileset.TilesetOverview(c, r)
        ctx.moveTo(c - 0.5, r - 0.5)
        ctx.lineTo(c - 0.5, r + 0.5 + Level.TILE_SIZE)
        ctx.lineTo(c + 0.5 + Level.TILE_SIZE, r + 0.5 + Level.TILE_SIZE)
        ctx.lineTo(c + 0.5 + Level.TILE_SIZE, r - 0.5)
        ctx.closePath()
        ctx.stroke()

    _onOverviewClick: (evt) ->
        [offsetX, offsetY] = Editors.getEvtOffset(evt)
        [col, row] = SpaceConversion.TilesetOverview.Tileset(offsetX, offsetY)
        @setTile(row, col)
        evt.preventDefault()
        
    moveSelection: (dr, dc) ->
        [r, c] = @tile
        r = rolling(0, r + dr, @numRows)
        c = rolling(0, c + dc, @numRows)
        @setTile(r, c)

    setTile: (r, c) ->
        r = Math.max(r, 0)
        c = Math.max(c, 0)
        
        @brush.setTile(r, c, @brush.tile[2])
        
        # $("#tile-code").val(@tile)
    
    _onTileChanged: (tile) ->
        r = tile[0]
        c = tile[1]
        @tile = [r, c]
        @_redrawOverview()
        @_drawTile(r, c, @heightMapContext, TilesetEditor.TILE_PREVIEW_SIZE)
        @_drawHeightMap(r, c)

    _drawTile: (r, c, ctx, size) ->
        ctx.clearRect(0, 0, size + 2, size + 2)
        
        if @image.complete and @image.src # because firefox falls over otherwise
            ctx.drawImage(
                @image,
                c * (Level.TILE_SIZE + 1) + 1,
                r * (Level.TILE_SIZE + 1) + 1,
                Level.TILE_SIZE,
                Level.TILE_SIZE,
                1, 1, size, size
            )
        
    _drawHeightMap: (r, c) ->
        ctx = @heightMapContext
        
        heightMap = @tileset.tiles[@tile]
        if heightMap
            scale = TilesetEditor.TILE_PREVIEW_SIZE / Level.TILE_SIZE
            ctx.fillStyle = "rgba(70,70,255,0.25)"
            ctx.strokeStyle = "rgba(0,0,0,0.75)"
            ctx.lineWidth = 1
            ctx.lineJoin = 'miter'
            ctx.beginPath()
            farCorner = SpaceConversion.Tile.TilePreview(Level.TILE_SIZE, Level.TILE_SIZE)
            farCorner[0] += 0.5
            farCorner[1] += 0.5
            farEdge = 1 + TilesetEditor.TILE_PREVIEW_SIZE + 0.5
            ctx.moveTo(0.5, farCorner[1])
            prevHeight = 0
            for i in [0...Level.TILE_SIZE] by 1
                height = Tile.CHAR_HEIGHT[heightMap.height[i]]
                if height is null
                    height = 0
                if height > prevHeight
                    previewPoint = SpaceConversion.Tile.TilePreview(i, Level.TILE_SIZE - height)
                    ctx.lineTo(previewPoint[0] - 0.5, previewPoint[1] - 0.5)
                else
                    previewPoint = SpaceConversion.Tile.TilePreview(i, Level.TILE_SIZE - prevHeight)
                    ctx.lineTo(previewPoint[0] + 0.5, previewPoint[1] - 0.5)
                    previewPoint = SpaceConversion.Tile.TilePreview(i, Level.TILE_SIZE - height)
                    ctx.lineTo(previewPoint[0] + 0.5, previewPoint[1] - 0.5)
                previewPoint = SpaceConversion.Tile.TilePreview(i + 1, Level.TILE_SIZE - height)
                ctx.lineTo(previewPoint[0] - 0.5, previewPoint[1] - 0.5)
                prevHeight = height
            ctx.lineTo(previewPoint[0] + 0.5, previewPoint[1] - 0.5)
            ctx.lineTo(farCorner[0], farCorner[1])
            ctx.lineTo(0.5, farCorner[1])
            ctx.fill()
            ctx.stroke()
