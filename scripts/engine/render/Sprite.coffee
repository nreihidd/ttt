# =========================================================
# Sprite

declare class Sprite
    constructor: (url, size) ->
        @spriteSheet = SpriteSheet.load url
        @position    = [0, 0]
        @rotation    = 0
        @scale       = [1, 1]
        @size        = size
        @alpha       = 1
        
        @animation          = "stand"
        @frameIndex         = 0
        @frameIndexDuration = 0
        @frameIndexLoc      = [0, 0]
        
        @spriteSheet.events.ready.listen =>
            @setAnimationRestart(@animation)

    setSpritesheetURL: (url) ->
        @spriteSheet = SpriteSheet.load url
        @spriteSheet.events.ready.listen =>
            @setAnimationRestart(@animation)
        
    _setFrame: (frameNumber) ->
        @frameIndex = frameNumber
        anim = @spriteSheet.animations[@animation]
        frame = anim[@frameIndex]
        @frameIndexDuration = frame[0] / (1000 / Engine.LOGIC_FPS)
        @frameIndexLoc[0] = frame[1]
        @frameIndexLoc[1] = frame[2]

    _getFirstAnimation: ->
        for animation of @spriteSheet.animations
            return animation

    setAnimationRestart: (animStr) ->
        if @spriteSheet.events.ready.done
            if not (animStr of @spriteSheet.animations)
                anim = @_getFirstAnimation()
                if anim == @animation or not anim
                    return
                animStr = anim
            @animation = animStr
            @_setFrame(0)
        
    setAnimation: (animStr) ->
        if @animation isnt animStr
            @setAnimationRestart animStr

    _tickAnimation: ->
        if @frameIndexDuration > 0
            @frameIndexDuration -= 1
            if @frameIndexDuration <= 0
                anim = @spriteSheet.animations[@animation]
                if @frameIndex >= anim.length - 1
                    @_setFrame(0)
                else
                    @_setFrame(this.frameIndex + 1)

    getTextureBounds: ->
        return @spriteSheet.getBounds @frameIndexLoc[0], @frameIndexLoc[1]

    getBounds: ->
        halfWidth  = @size[0] / 2.0
        halfHeight = @size[1] / 2.0
        
        return (
            left:   -halfWidth
            right:   halfWidth
            top:     halfHeight
            bottom: -halfHeight
        )

    logic: ->
        if @spriteSheet.events.ready.done
            @_tickAnimation()
