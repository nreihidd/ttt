#=========================================================
# Texture Loading

declare class Texture

    constructor: (url, @options = {}) ->
        @events = 
            ready: new Event false
        
        defaults =
            filtering: "nearest"
        applyDefaults @options, defaults
        
        id = gl.createTexture()
        @id = null
        loadImage url, (image) =>
            gl.bindTexture(gl.TEXTURE_2D, id)
            # gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
            gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image
            if @options.filtering == 'linear'
                gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
                gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
            else
                gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
                gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
            gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
            gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
            # gl.generateMipmap(gl.TEXTURE_2D)
            gl.bindTexture gl.TEXTURE_2D, null

            @id = id
            @width = image.width
            @height = image.height
            @events.ready.fire()

    bind: ->
        gl.bindTexture(gl.TEXTURE_2D, @id)

    @load = createCache
        key: (url, options) -> return url
        create: (url, options) -> return new Texture(url, options)

    @FULL_BOUNDS =
        'left':   0
        'top':    1
        'right':  1
        'bottom': 0
