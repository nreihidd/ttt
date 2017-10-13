#=========================================================
# Shader Program

declare class ShaderProgram
    constructor: (vsName, fsName) ->
        @program = gl.createProgram()
        gl.attachShader @program, loadShader(gl, fsName)
        gl.attachShader @program, loadShader(gl, vsName)
        gl.linkProgram @program
        
        if not gl.getProgramParameter(@program, gl.LINK_STATUS)
            console.error(gl.getProgramInfoLog(@program))
        
        gl.useProgram @program
        
        @locations = {}
        
        numAttributes = gl.getProgramParameter(@program, gl.ACTIVE_ATTRIBUTES)
        for i in [0...numAttributes] by 1
            attribute = gl.getActiveAttrib(@program, i)
            @locations[attribute.name] = gl.getAttribLocation(@program, attribute.name)
            gl.enableVertexAttribArray(@locations[attribute.name])

        numUniforms = gl.getProgramParameter(@program, gl.ACTIVE_UNIFORMS)
        for i in [0...numUniforms] by 1
            uniform = gl.getActiveUniform(@program, i)
            @locations[uniform.name] = gl.getUniformLocation(@program, uniform.name)

    @getProgram = createCache
        key: (vertexShaderName, fragmentShaderName) -> return vertexShaderName + " " + fragmentShaderName
        create: (vertexShaderName, fragmentShaderName) -> return new ShaderProgram(vertexShaderName, fragmentShaderName)