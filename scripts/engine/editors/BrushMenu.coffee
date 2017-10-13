#=========================================================
# Brush Menu

declare class BrushMenu
    constructor: (canvas, brush) ->
        @_visible = false
        @parentElement = "#quad-menu-position"

        #==========
        # Mouse wheel for brush size
        $(canvas).mousewheel (evt, delta) =>
            delta = clamp(-1, delta, 1)
            brush.setSize(brush.size + delta)
            $("#brush-menu-size").val(brush.size)
            evt.stopPropagation()
            evt.preventDefault()
        
        #==========
        # Tooltips
        $("#quad-menu-brush table td:first-child").each ->
            new Tooltip(this)
        
        #==========
        # Brush settings hotkeys
        Keyboard.registerHotkey Keyboard.KEYS.bracketOpen, =>
            brush.setSize(brush.size - 1)
            $("#brush-menu-size").val(brush.size)
        Keyboard.registerHotkey Keyboard.KEYS.bracketClose, =>
            brush.setSize(brush.size + 1)
            $("#brush-menu-size").val(brush.size)
            
        Keyboard.registerHotkey 'M', =>
            brush.smooth = not brush.smooth
            $("#brush-menu-smooth").prop("checked", brush.smooth)
        
        Keyboard.registerHotkey 'C', =>
            if brush.shape is 'square'
                brush.shape = 'circle'
                $("input[name=brush-menu-shape][value=circle]").prop("checked", true)
            else
                brush.shape = 'square'
                $("input[name=brush-menu-shape][value=square]").prop("checked", true)
            
        Keyboard.registerHotkey 'R', =>
            flags = brush.tile[2]
            flags ^= Level.FLAG_ROTATE_90
            if (flags & Level.FLAG_ROTATE_90) is 0
                flags ^= Level.FLAG_ROTATE_180
            brush.tile[2] = flags
        Keyboard.registerHotkey 'F', =>
            flags = brush.tile[2]
            flags ^= Level.FLAG_FLIP_VERTICAL
            brush.tile[2] = flags
            
        $("#brush-menu-size").change (evt) ->
            brush.setSize(parseInt($(this).val()))
        $("#brush-menu-smooth").change (evt) ->
            brush.smooth = $("#brush-menu-smooth").prop("checked")
        $("input[name=brush-menu-shape]").change (evt) ->
            brush.shape = $("input[name=brush-menu-shape]:checked").val()

    hideMenu: ->
        if @_visible
            $("#quad-menu-position").hide()
            @_visible = false
    
    toggleMenuAt: (x, y) ->
        @_visible = not @_visible
        if @_visible
            $("#quad-menu-position").show().css({
                left: x,
                top:  y
            })
        else
            $("#quad-menu-position").hide()