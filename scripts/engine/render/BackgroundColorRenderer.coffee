declare class BackgroundColorRenderer
    constructor: (@camera) ->
        @shader = ShaderProgram.getProgram("color-shader-vs", "color-shader-fs")
        QuadIndices.ensureCapacity(1)
        @vertexBuffer = gl.createBuffer()
        @observers =
            levelSize: new Observer =>
                @buildBuffer()

    setLevel: (@level) ->
        @buildBuffer()
        @observers.levelSize.observe(@level.observables.size)

    buildBuffer: ->
        gl.bindBuffer(gl.ARRAY_BUFFER, @vertexBuffer)

        bounds = @level.bounds

        vertexData = new Float32Array([
            bounds.left, bounds.top,
            bounds.right, bounds.top,
            bounds.right, bounds.bottom,
            bounds.left, bounds.bottom
        ])

        gl.bufferData(gl.ARRAY_BUFFER, vertexData, gl.STATIC_DRAW)

    draw: ->
        if not @level
            return

        gl.useProgram @shader.program
        QuadIndices.bind()

        gl.uniform4fv @shader.locations.uColor, @level.backgroundColor
        gl.uniform2fv @shader.locations.uCameraPos, @camera.pos
        gl.uniform2fv @shader.locations.uScreenSize, [gl.viewportWidth, gl.viewportHeight]

        gl.bindBuffer(gl.ARRAY_BUFFER, @vertexBuffer)
        gl.vertexAttribPointer(@shader.locations.aVertexPosition, 2, gl.FLOAT, false, 8, 0)
        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_SHORT, 0)