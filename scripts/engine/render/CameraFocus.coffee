declare class CameraFocus
    constructor: (@priority, @bounds) ->
        # @bounds should be one of camera's bounds, since those will be updated in place
        @pos = [0, 0]

    setCenter: (x, y) ->
        x = clamp(@bounds.left,   x, @bounds.right)
        y = clamp(@bounds.bottom, y, @bounds.top)

        @pos[0] = Math.round(x)
        @pos[1] = Math.round(y)
        
    moveCenter: (x, y) ->
        speedX = Math.max(Camera.MAX_SPEED, Math.abs((x - @pos[0]) * 5 / Engine.LOGIC_FPS))
        speedY = Math.max(Camera.MAX_SPEED, Math.abs((y - @pos[1]) * 5 / Engine.LOGIC_FPS))
    
        @setCenter(
            clamp(@pos[0] - speedX, x, @pos[0] + speedX),
            clamp(@pos[1] - speedY, y, @pos[1] + speedY)
        )
        
    clampCenter: (bounds) ->
        @setCenter(
            clamp(bounds.left, @pos[0], bounds.right),
            clamp(bounds.bottom, @pos[1], bounds.top)
        )