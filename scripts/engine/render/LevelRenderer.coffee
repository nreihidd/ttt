#=========================================================
# Level Renderer

###
For now put the entire level into a giant vertex array and let webgl do
   the culling on its own.  This means only one draw call.  For a level
   editor you would:
    o have the vertex buffer use DYNAMIC_DRAW
    o store each tile's offset into the array
    o to change a tile's type:
        - from visible to visible:
            bufferSubData that tile's offset and replace its texture coordinates
        - from invisible to visible:
            append the data to the end of the array, extending both the vertex
            array and index array as necessary
        - from visible to invisible:
            put the last vertex data into this one's spot, this would require a
            reverse lookup to update that tile's offset, then reduce the number
            to render by 1
             OR
            just change its texture coordinates to empty space and let it render
            the invisible quad
            
   Alternative methods would be:
    o build VBO chunks as STATIC_DRAW, cull by chunk in javascript
        - could do editor as described above, or simply rebuild the chunk entirely
          when a member tile changes
    o build VBO each frame, cull by tile
        - editor would require nothing extra, as the VBO would be rebuilt from
          the now modified tile data automatically
    o render to a texture once, render a single quad with that new texture as the level
        - editor would have to re-render any modified areas
###

declare class LevelRenderer
    @TILE_VERTEX_SIZE = Float32Array.BYTES_PER_ELEMENT * 4 * 4
    
    constructor: (@level, @camera) ->
        @observables = 
            status: new Observable(false)

        @shader = ShaderProgram.getProgram("level-shader-vs", "sprite-shader-fs")
        
        @chunks = new Dict2D()
        
        @level.events.edited.listen @_onLevelEdit.bind(this)

        # Observers
        @observers =
            levelTileset: new Observer (tileset) =>
                @observables.status.update(false)
                @tileSheet = new TileSheet(tileset.image, [Level.TILE_SIZE, Level.TILE_SIZE])
                @tileSheet.events.ready.listen @_buildBuffer.bind(this)
            levelSize: new Observer (size) =>
                @_onLevelResize(size)

        @observers.levelTileset.observe(@level.observables.tileset)
        @observers.levelSize.observe(@level.observables.size)
        
    _onLevelEdit: (row, col) ->
        chunkX = Math.floor(col / LevelRenderChunk.CHUNK_SIZE)
        chunkY = Math.floor(row / LevelRenderChunk.CHUNK_SIZE)
        chunk  = @chunks.get(chunkX, chunkY)
        if chunk
            chunk.dataDirty = true
            
    _onLevelResize: (levelSize) ->
        chunkMaxY = Math.floor(levelSize[0] / LevelRenderChunk.CHUNK_SIZE)
        chunkMaxX = Math.floor(levelSize[1] / LevelRenderChunk.CHUNK_SIZE)
        
        # Remove chunks that were cropped out
        toDelete = []
        @chunks.forEach (x, y, chunk) ->
            if x > chunkMaxX or y > chunkMaxY
                toDelete.push(chunk)
        for chunk in toDelete
            @chunks.remove(chunk.chunkX, chunk.chunkY)
            chunk.destroy(gl)
        
        # Add new chunks
        for x in [0..chunkMaxX] by 1
            for y in [0..chunkMaxY] by 1
                if not @chunks.has(x, y)
                    @chunks.set(x, y, new LevelRenderChunk(gl, x, y, this))
                    
        # Rebuild edge chunks
        for x in [0..chunkMaxX]
            @chunks.get(x, 0).dataDirty = true
            @chunks.get(x, chunkMaxY).dataDirty = true
        for y in [0..chunkMaxY]
            @chunks.get(0, y).dataDirty = true
            @chunks.get(chunkMaxX, y).dataDirty = true
        

    @applyTileFlags = (bounds, textureBounds, flags) ->
        a = [bounds.left, bounds.top]
        b = [bounds.right, bounds.top]
        c = [bounds.right, bounds.bottom]
        d = [bounds.left, bounds.bottom]
        
        # The flipped texture coordinates made a huge mess of everything, and
        # what should have been clockwise is now counter-clockwise and the
        # order of applying the vertical flip in this function is what makes
        # these render results match the collision and diagrams, and I
        # still don't know why.
        if (flags & Level.FLAG_FLIP_VERTICAL) isnt 0
            t = a
            a = d
            d = t
            t = b
            b = c
            c = t
        if (flags & Level.FLAG_ROTATE_90) isnt 0
            t = b
            b = c
            c = d
            d = a
            a = t
        if (flags & Level.FLAG_ROTATE_180) isnt 0
            t = a
            a = c
            c = t
            t = b
            b = d
            d = t
        
        return [
            a[0], a[1],
            textureBounds.left,  textureBounds.top,
            
            b[0], b[1],
            textureBounds.right, textureBounds.top,
            
            c[0], c[1],
            textureBounds.right, textureBounds.bottom,
            
            d[0], d[1],
            textureBounds.left, textureBounds.bottom
        ]

    _buildBuffer: ->
        if @_initialBuildComplete
            @chunks.forEach (x, y, chunk) ->
                chunk.dataDirty = true
        else
            levelSize = @level.getLevelSize()
            levelSize[0] = Math.floor(levelSize[0] / LevelRenderChunk.CHUNK_SIZE)
            levelSize[1] = Math.floor(levelSize[1] / LevelRenderChunk.CHUNK_SIZE)
            
            for x in [0..levelSize[1]] by 1
                for y in [0..levelSize[0]] by 1
                    @chunks.set(x, y, new LevelRenderChunk(gl, x, y, this))
            
            @_initialBuildComplete = true
        @observables.status.update(true)

    draw: ->
        if not @observables.status.value
            return

        gl.useProgram @shader.program
        QuadIndices.bind()
        
        
        gl.activeTexture gl.TEXTURE0
        gl.uniform1i  @shader.locations.uSampler, 0
        gl.uniform2fv @shader.locations.uCameraPos, @camera.pos
        gl.uniform2fv @shader.locations.uScreenSize, [gl.viewportWidth, gl.viewportHeight]
        
        @tileSheet.bind()
        
        viewBounds = SpaceConversion.bounds(SpaceConversion.Game.GameLevelTile, @camera.getViewBounds())
        for side of viewBounds
            viewBounds[side] = Math.floor(viewBounds[side] / LevelRenderChunk.CHUNK_SIZE)
        # debugInfo.chunkView = "[#{viewBounds.left}, #{viewBounds.right}] [#{viewBounds.bottom}, #{viewBounds.top}]"
        for x in [viewBounds.left..viewBounds.right] by 1
            for y in [viewBounds.bottom..viewBounds.top] by 1
                chunk = @chunks.get(x, y)
                if not chunk
                    continue
                chunk.prepareBuffer(gl)
                gl.bindBuffer(gl.ARRAY_BUFFER, chunk.vertexBuffer)
                gl.vertexAttribPointer(@shader.locations.aVertexPosition, 2, gl.FLOAT, false, 16, 0)
                gl.vertexAttribPointer(@shader.locations.aTextureCoord, 2, gl.FLOAT, false, 16, 8)
                gl.drawElements(gl.TRIANGLES, 6 * chunk.numTiles, gl.UNSIGNED_SHORT, 0)

    destroy: ->
        @chunks.forEach (x, y, chunk) ->
            chunk.destroy(gl)

declare class LevelRenderChunk
    @CHUNK_SIZE = 32
    constructor: (gl, @chunkX, @chunkY, @levelRenderer) ->
        @vertexBuffer = gl.createBuffer()
        @vertexData   = null
        @bufferDirty  = true
        @dataDirty    = true
        @numTiles     = undefined
        
    buildTile: (row, col, tile) ->
        bounds = SpaceConversion.bounds(SpaceConversion.GameLevelTile.Game,
            left:    col
            right:   col + 1
            bottom:  row
            top:     row + 1
        )
        textureBounds = @levelRenderer.tileSheet.getBounds(tile[0], tile[1])
        
        return LevelRenderer.applyTileFlags(bounds, textureBounds, tile.flags)

    buildData: ->
        tiles     = @levelRenderer.level.tiles
        levelSize = @levelRenderer.level.getLevelSize()
    
        rowFirst = clamp(0, @chunkY * LevelRenderChunk.CHUNK_SIZE, levelSize[0] - 1)
        rowLast  = clamp(0, (@chunkY + 1) * LevelRenderChunk.CHUNK_SIZE - 1, levelSize[0] - 1)
        colFirst = clamp(0, @chunkX * LevelRenderChunk.CHUNK_SIZE, levelSize[1] - 1)
        colLast  = clamp(0, (@chunkX + 1) * LevelRenderChunk.CHUNK_SIZE - 1, levelSize[1] - 1)
        
        @numTiles = 0
        for r in [rowFirst..rowLast] by 1
            for c in [colFirst..colLast] by 1
                if tiles[r][c]
                    @numTiles += 1
        
        vertexDataSize = 4 * 4 * @numTiles
        if not @vertexData
            @vertexData = new Float32Array(vertexDataSize)
        else if @vertexData.length < vertexDataSize
            nextSize = clamp(vertexDataSize, @vertexData.length * 2,
                             LevelRenderChunk.CHUNK_SIZE * LevelRenderChunk.CHUNK_SIZE * 4 * 4)
            @vertexData = new Float32Array(nextSize)
        
        offset = 0
        for r in [rowFirst..rowLast] by 1
            for c in [colFirst..colLast] by 1
                if tiles[r][c]
                    @vertexData.set(@buildTile(r, c, tiles[r][c]), 4 * 4 * offset)
                    offset += 1
        
        @dataDirty = false
        @bufferDirty = true
        
    prepareBuffer: (gl) ->
        if @dataDirty
            @buildData()
        if @bufferDirty
            QuadIndices.ensureCapacity(@numTiles)
            gl.bindBuffer(gl.ARRAY_BUFFER, @vertexBuffer)
            gl.bufferData(gl.ARRAY_BUFFER, @vertexData, gl.STATIC_DRAW)
            @bufferDirty = false
    
    destroy: (gl) ->
        gl.deleteBuffer(@vertexBuffer)
