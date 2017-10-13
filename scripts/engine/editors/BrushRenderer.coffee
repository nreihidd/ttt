#=========================================================
# BrushRenderer

declare class BrushRenderer
    constructor: (@brush, @camera) ->
        @shader = ShaderProgram.getProgram("level-shader-vs", "brush-shader-fs")
        @vertexBuffer = gl.createBuffer()
        @tileSheet = null
        
        @prev =
            num: 0
            row: 0
            col: 0
            flags: 0
        @dirty = false
            
    _buildTile: (row, col) ->
        bounds = SpaceConversion.bounds(SpaceConversion.GameLevelTile.Game,
            left:    col
            right:   col + 1
            top:     row + 1
            bottom:  row
        )
        textureBounds = @tileSheet.getBounds @brush.tile[0], @brush.tile[1]
        
        return LevelRenderer.applyTileFlags(bounds, textureBounds, @brush.tile[2])
        
    _updateBuffer: ->
        @numTiles = @brush.countTiles()
        if not @dirty and @numTiles is @prev.num and @brush.tile[0] is @prev.row and @brush.tile[1] is @prev.col and @brush.tile[2] is @prev.flags
            return
        
        QuadIndices.ensureCapacity(@numTiles)
        
        gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
        vertexData = new Float32Array 4 * 4 * @numTiles
        offset = 0
        @brush.forEachTile (row, col) =>
            vertexData.set @_buildTile(@brush.row - row, @brush.col - col), 4 * 4 * offset
            offset += 1
        gl.bufferData gl.ARRAY_BUFFER, vertexData, gl.STATIC_DRAW
        
        @prev.num = @numTiles
        @prev.row = @brush.row
        @prev.col = @brush.col
        @prev.flags = @brush.flags
        @dirty = false
        
    draw: ->
        if not @tileSheet or not @brush.isVisible() or not Editors.toolsVisible
            return
            
        @_updateBuffer()
        
        gl.useProgram @shader.program
        gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
        QuadIndices.bind()
        
        gl.vertexAttribPointer @shader.locations.aVertexPosition, 2, gl.FLOAT, false, 16, 0
        gl.vertexAttribPointer @shader.locations.aTextureCoord, 2, gl.FLOAT, false, 16, 8
        
        camera = []
        camera[0] = @camera.pos[0] - @brush.position[0] # @brush.col * Level.TILE_SIZE
        camera[1] = @camera.pos[1] - @brush.position[1] # @brush.row * Level.TILE_SIZE
        
        gl.activeTexture gl.TEXTURE0
        gl.uniform1i  @shader.locations.uSampler, 0
        gl.uniform2fv @shader.locations.uCameraPos, camera
        gl.uniform2fv @shader.locations.uScreenSize, [gl.viewportWidth, gl.viewportHeight]
        if @brush.mode is 'draw'
            gl.uniform4fv @shader.locations.uColor, [0.0, 1, 1, 0.1]
            gl.uniform1f  @shader.locations.uAlpha, 0.8
        else
            gl.uniform4fv @shader.locations.uColor, [1.0, 0.0, 0.0, 0.5]
            gl.uniform1f  @shader.locations.uAlpha, 0.0
        
        @tileSheet.bind()
        gl.drawElements gl.TRIANGLES, 6 * @numTiles, gl.UNSIGNED_SHORT, 0
