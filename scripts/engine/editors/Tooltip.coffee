
declare class Tooltip
    $tooltipDiv = null
    counter = 0
    
    create = ->
        if not $tooltipDiv
            $tooltipDiv = $("#tooltip") # $("<div id='tooltip'>testing</div>").appendTo('body')
    
    mouseOut = ->
        if --counter is 0
            if $tooltipDiv
                $tooltipDiv.stop(true, true).fadeOut(100)
    mouseOver = (body) ->
        if counter++ is 0
            create()
            $tooltipDiv.stop(true, true).show()
        $tooltipDiv.html(body)
        
    constructor: (el, options) ->
        $el = $(el)
        if options is undefined
            @body = $el.find('.tooltip').html()
        else if options.body
            @body = options.body
        else if options.name and options.description and not options.hotkey
            @body = """
                <span class='name'>#{options.name}</span><br>
                <span class='description'>#{options.description}</span>
            """
        else
            @body = """
                <span class='hotkey'>#{options.hotkey}</span> -
                <span class='name'>#{options.name}</span><br>
                <span class='description'>#{options.description}</span>
            """
            
        $el.mousemove (evt) =>
            $tooltipDiv.css({
                left: evt.pageX + 15
                top:  evt.pageY + 15
            })
        $el.mouseout (evt) =>
            mouseOut()
        $el.mouseover (evt) =>
            mouseOver(@body)

# TODO: turn this into a jquery function
window.getDisplacementIntoViewport = ($elem) ->
    offset = $elem.offset()
    left = offset.left
    top = offset.top
    right = offset.left + $elem.width()
    bottom = offset.top + $elem.height()

    dx = 0
    if left < 0 and right > window.innerWidth
        dx = window.innerWidth - (right - left) / 2
    else if left < 0
        dx = 0 - left
    else if right > window.innerWidth
        dx = window.innerWidth - right

    dy = 0
    if top < 0 and bottom > window.innerHeight
        dy = window.innerHeight - (bottom - top) / 2
    else if top < 0
        dy = 0 - top
    else if bottom > window.innerHeight
        dy = window.innerHeight - bottom

    return [dx, dy]
