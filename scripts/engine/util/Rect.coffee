#=========================================================
# Rect

declare class Rect
    constructor: (@x, @y, @w, @h) ->
        ;

    clone: ->
        return new Rect @x, @y, @w, @h

    translate: (x, y) ->
        @x += x
        @y += y

    setTop: (val) ->
        @y = val - (@h / 2)
    getTop: ->
        return @y + (@h / 2)

    setBottom: (val) ->
        @y = val + (@h / 2)
    getBottom: ->
        return @y - (@h / 2)

    setLeft: (val) ->
        @x = val + (@w / 2)
    getLeft: ->
        return @x - (@w / 2)

    setRight: (val) ->
        @x = val - (@w / 2)
    getRight: ->
        return @x + (@w / 2)

    toBounds: ->
        return (
            left:   @getLeft()
            right:  @getRight()
            top:    @getTop()
            bottom: @getBottom()
        )
        
    containsPoint: (x, y) ->
        return x > @getLeft() and x < @getRight() and y > @getBottom() and y < @getTop()

#=========================================================
# Bounds

declare "Direction", Direction =
    directions: ['left', 'right', 'bottom', 'top']

    opposite:
        'left': 'right'
        'right': 'left'
        'top': 'bottom'
        'bottom': 'top'

    x:
        'left':  true
        'right': true

    y:
        'bottom': true
        'top':    true

    unit:
        'left':   -1
        'right':   1
        'bottom': -1
        'top':     1
    
    dirOf: (dir, a, b) ->
        if Direction.unit[dir] is 1
            return a > b
        else
            return a < b

Direction.xaxis =
    low: 'left'
    high: 'right'
Direction.yaxis =
    low: 'bottom'
    high: 'top'
Direction.xaxis.other = Direction.yaxis
Direction.yaxis.other = Direction.xaxis
Direction.axis =
    left:   Direction.xaxis
    right:  Direction.xaxis
    bottom: Direction.yaxis
    top:    Direction.yaxis

window.boundsSet = (a, b) ->
    a.left   = b.left
    a.right  = b.right
    a.bottom = b.bottom
    a.top    = b.top

window.boundsIntersection = (a, b, result) ->
    if result is undefined
        result = {}
    result.left   = Math.max(a.left,   b.left)
    result.right  = Math.min(a.right,  b.right)
    result.bottom = Math.max(a.bottom, b.bottom)
    result.top    = Math.min(a.top,    b.top)
    if result.right < result.left or result.top < result.bottom
        return false
    return result
    
window.boundsUnion = (a, b, result) ->
    if result is undefined
        result = {}
    result.left   = Math.min(a.left,   b.left)
    result.right  = Math.max(a.right,  b.right)
    result.bottom = Math.min(a.bottom, b.bottom)
    result.top    = Math.max(a.top,    b.top)
    return result

window.boundsCopy = (a) ->
    return {
        left:   a.left
        right:  a.right
        bottom: a.bottom
        top:    a.top
    }

window.boundsFlat = (a) ->
    return a.right == a.left or a.bottom == a.top
