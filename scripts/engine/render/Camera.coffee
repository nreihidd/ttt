#=========================================================
# Camera

declare class Camera
    @MAX_SPEED = 20
    constructor: ->
        @pos = [0, 0]
        @foci = []

        @levelBounds = {}
        @centerBounds = {}
        
    getViewBounds: ->
        hw = gl.viewportWidth / 2
        hh = gl.viewportHeight / 2
        return {
            left:   @pos[0] - hw,
            right:  @pos[0] + hw,
            bottom: @pos[1] - hh,
            top:    @pos[1] + hh
        }

    setBounds: (bounds) ->
        boundsSet(@levelBounds, bounds)

        hw = gl.viewportWidth / 2
        hh = gl.viewportHeight / 2
            
        left = @levelBounds.left + hw
        right = @levelBounds.right - hw
        if left > right
            left = right = (left + right) / 2
            
        top = @levelBounds.top - hh
        bottom = @levelBounds.bottom + hh
        if bottom > top
            bottom = top = (bottom + top) / 2
        
        boundsSet(@centerBounds, {left, right, bottom, top})
        return

    addFocus: (focus) ->
        i = 0
        loop
            break if i >= @foci.length or focus.priority > @foci[i].priority
            i += 1
        @foci.splice(i, 0, focus)

    removeFocus: (focus) ->
        i = 0
        loop
            break if i >= @foci.length
            if @foci[i] is focus
                @foci.splice(i, 1)
                break
            i += 1

    update: ->
        if @foci.length is 0
            return
        focus = @foci[0]

        @pos[0] = Math.round(focus.pos[0])
        @pos[1] = Math.round(focus.pos[1])

        if gl.viewportWidth % 2 == 1
            @pos[0] -= 0.5
        if gl.viewportHeight % 2 == 1
            @pos[1] -= 0.5
