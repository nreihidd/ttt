#=========================================================
# QuadIndices

declare "QuadIndices", QuadIndices = new class
    needInit = true
    capacity = 64
    buffer = undefined
    
    calculateNewSize = (size) ->
        val = capacity
        while val < size
            val *= 2
        return val
    
    prepareIndices = (size) ->
        gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, buffer
        indices = new Uint16Array size * 6
        for i in [0...size] by 1
            s = i * 4
            indices.set [s, s + 1, s + 2, s, s + 2, s + 3], i * 6

        gl.bufferData gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW
        capacity = size
    
    init = (size) ->
        needInit = false
        buffer = gl.createBuffer()
        prepareIndices calculateNewSize(size)
    
    bind: ->
        if needInit
            init 64
        gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, buffer
    
    ensureCapacity: (numQuads) ->
        if needInit
            init numQuads
        if numQuads > capacity
            prepareIndices calculateNewSize(numQuads)
