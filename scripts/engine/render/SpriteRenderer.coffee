#=========================================================
# Sprite Manager

declare class SpriteRenderer
    @SIZE_OF_SPRITE_DATA = Float32Array.BYTES_PER_ELEMENT * 4 * 10

    constructor: (camera) ->
        @_sprites = {}
        @_capacity = 10
        @camera = camera
        @init()

    _setBufferCapacity: (capacity) ->
        @_capacity = capacity
        gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
        gl.bufferData gl.ARRAY_BUFFER, SpriteRenderer.SIZE_OF_SPRITE_DATA * @_capacity, gl.DYNAMIC_DRAW
        QuadIndices.ensureCapacity @_capacity
        @vertexArray = new Float32Array(@_capacity * SpriteRenderer.SIZE_OF_SPRITE_DATA / Float32Array.BYTES_PER_ELEMENT)

    _increaseCapacity: () ->
        @_setBufferCapacity @_capacity * 2

    add: (sprite) ->
        id = sprite.spriteSheet.id
        if not (id of @_sprites)
            @_sprites[id] = []
        @_sprites[id].push sprite
        if @_sprites[id].length > @_capacity
            @_increaseCapacity()

    remove: (sprite) ->
        id = sprite.spriteSheet.id
        index = @_sprites[id].indexOf sprite
        @_sprites[id].splice index, 1
        
        if @_sprites[id].length is 0
            delete @_sprites[id]

    init: () ->
        @vertexBuffer = gl.createBuffer()
        @_setBufferCapacity @_capacity
        @shader = ShaderProgram.getProgram("sprite-shader-vs", "sprite-shader-fs")

    _prepareSprite: (offset, sprite) ->
        bounds = sprite.getBounds()
        textureBounds = sprite.getTextureBounds()
        
        vertices = [
            [bounds.left, bounds.top,
            textureBounds.left,  textureBounds.top],
            
            [bounds.right, bounds.top,
            textureBounds.right, textureBounds.top],
            
            [bounds.right, bounds.bottom,
            textureBounds.right, textureBounds.bottom],
            
            [bounds.left, bounds.bottom,
            textureBounds.left, textureBounds.bottom]
        ]
        modifiers = [
            sprite.position[0], sprite.position[1], sprite.rotation, sprite.scale[0], sprite.scale[1], sprite.alpha
        ]
        
        indexOffset = offset * SpriteRenderer.SIZE_OF_SPRITE_DATA / Float32Array.BYTES_PER_ELEMENT
        for i in [0...4]
            @vertexArray.set(vertices[i], indexOffset + i * 10)
            @vertexArray.set(modifiers, indexOffset + i * 10 + 4)

    draw: () ->
        maxSprites = 0
        for id of @_sprites
            maxSprites = Math.max maxSprites, @_sprites[id].length
        
        gl.useProgram @shader.program
        gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
        QuadIndices.bind()
        
        gl.vertexAttribPointer @shader.locations.aVertexPosition, 2, gl.FLOAT, false, 40, 0
        gl.vertexAttribPointer @shader.locations.aTextureCoord,   2, gl.FLOAT, false, 40, 8
        gl.vertexAttribPointer @shader.locations.aSpritePosition, 2, gl.FLOAT, false, 40, 16
        gl.vertexAttribPointer @shader.locations.aSpriteRotation, 1, gl.FLOAT, false, 40, 24
        gl.vertexAttribPointer @shader.locations.aSpriteScale,    2, gl.FLOAT, false, 40, 28
        gl.vertexAttribPointer @shader.locations.aSpriteAlpha,    1, gl.FLOAT, false, 40, 36
        
        gl.activeTexture gl.TEXTURE0
        gl.uniform1i @shader.locations.uSampler, 0
        gl.uniform2fv @shader.locations.uCameraPos, @camera.pos
        gl.uniform2fv @shader.locations.uScreenSize, [gl.viewportWidth, gl.viewportHeight]
        
        for id of @_sprites
            spriteSheet = @_sprites[id][0].spriteSheet
            
            spriteSheet.bind()
                
            numSprites = @_sprites[id].length
            # Drawing all sprites sharing this spritesheet at once would simply
            # require setting up the appropriate index array
            for sprite, i in @_sprites[id]
                @_prepareSprite i, sprite
            gl.bufferSubData(gl.ARRAY_BUFFER, 0, @vertexArray)

            gl.drawElements(gl.TRIANGLES, 6 * numSprites, gl.UNSIGNED_SHORT, 0)
