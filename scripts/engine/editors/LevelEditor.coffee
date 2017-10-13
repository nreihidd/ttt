#=========================================================
# Level Editor -- Singleton

declare class LevelEditor

    # TODO:
    #       add area selection + copy/paste a la wc3

    constructor: (@canvas, @brush) ->
        @rightClickMenu = new RightclickMenu(Engine.canvas, @brush)
        @rightClickMenu.setMenu(@rightClickMenu.entityMenu)

        @createMouseHandlers()
        @setMouseHandler(@handHandler)
        
        @undoStack = []
        @redoStack = []
        @pendingDiff = []
        
        #==========
        # Clicking/dragging/scrolling
        $canvas = $(@canvas)
        
        mousePressed = false
        @mouseInCanvas = false
        $canvas[0].onselectstart = (evt) -> evt.stopPropagation(); evt.preventDefault();
        $canvas.mousedown (evt) =>
            @_updateMousePosition(evt)
            if evt.which == 1
                if evt.altKey
                    [col, row] = SpaceConversion.Game.GameLevelTile(@mouseGameX, @mouseGameY)
                    clickedTile = Engine.level.getTile(row, col)
                    if clickedTile isnt null
                        @brush.setTile(clickedTile[0], clickedTile[1], clickedTile.flags)
                    evt.preventDefault()
                else
                    mousePressed = true
                    @mouseHandler?.down(evt)
                    evt.preventDefault()
                    $(document.activeElement).blur()
        $canvas.mouseup (evt) =>
            @_updateMousePosition(evt)
            if evt.which == 1
                @mouseHandler?.up(evt)
            else if evt.which == 3
                evt.preventDefault()
        $(document).mouseup (evt) =>
            if evt.which == 1
                @mouseHandler?.up(evt)
                mousePressed = false
        $canvas.mousemove (evt) =>
            @_updateMousePosition(evt)
            if mousePressed
                @mouseHandler?.drag(evt)
        $canvas.mouseout (evt) =>
            @mouseInCanvas = false
            @mouseHandler?.disable()
        $canvas.mouseover (evt) =>
            @mouseInCanvas = true
            @mouseHandler?.enable()
            
        #==========
        # Buttons
        $('#button-arrow').addClass('active')
        @modeButtons =
            '#button-arrow':
                name: 'Arrow'
                hotkey: 'X'
                tooltip: 'The default cursor, disables editing.'
                mode: 'none'
            '#button-draw':
                name: 'Draw'
                hotkey: 'B'
                tooltip: 'The drawing brush, allows you to place tiles.'
                mode: 'draw'
            '#button-erase':
                name: 'Erase'
                hotkey: 'E'
                tooltip: 'The erasing brush, allows you to remove tiles.'
                mode: 'erase'
        
        createModeHandler = (mode) => return => @switchMode(mode)
        preventDefault = (evt) ->
            evt.preventDefault()
            evt.stopPropagation()
        for button, opts of @modeButtons
            handler = createModeHandler(opts.mode)
            $(button).click(handler)
            $(button).mousedown preventDefault
            new Tooltip($(button)[0], {name: opts.name, hotkey: opts.hotkey, description: opts.tooltip})
            Keyboard.registerHotkey(opts.hotkey, handler)
            
        Engine.events.logicEditor.listen =>
            @_updateMouseGamePosition()
            @mouseHandler?.logic()
            
        Keyboard.registerKey 'Z', (key, down, evt) =>
            if down and evt.ctrlKey
                if evt.shiftKey
                    @redo()
                else
                    @undo()
        
    setMouseHandler: (handler) ->
        if @mouseHandler is handler
            return
        @mouseHandler?.disable()
        if handler
            @mouseHandler = handler
        else
            delete @mouseHandler
        if @mouseInCanvas
            @mouseHandler?.enable()
        
    createMouseHandlers: ->
        @brushHandler =
            enable: =>
                @brush.visible = true
            disable: =>
                @brush.visible = false
                @_appendDiff()
            down: (evt) =>
                @brushPoint()
            up: (evt) =>
                @_appendDiff()
            drag: (evt) =>
                @brushPoint()
            logic: =>
                if @brush.visible
                    @brush.setPosition(@mouseGameX, @mouseGameY)
        
        @handHandler =
            enable: =>
                # do nothing
            disable: =>
                DraggableTrait.mouseDisable()
            down: (evt) =>
                DraggableTrait.mouseDown(@mouseGameX, @mouseGameY)
            up: (evt) =>
                DraggableTrait.mouseUp()
            drag: (evt) =>
                DraggableTrait.mouseMove(@mouseGameX, @mouseGameY)
            logic: =>
                DraggableTrait.mouseMove(@mouseGameX, @mouseGameY)
                
    switchMode: (to) ->
        if @mode is to
            return

        $canvas = $(@canvas)
        $canvas.removeClass(@mode)
        @mode = to
        for button, opts of @modeButtons
            if opts.mode is @mode
                $(button).addClass('active')
            else
                $(button).removeClass('active')
        $canvas.addClass(@mode)
        
        if @mode in ['draw', 'erase']
            @brush.mode = to
            @setMouseHandler(@brushHandler)
            @rightClickMenu.setMenu(@rightClickMenu.brushMenu)
        else
            @brush.mode = 'none'
            @setMouseHandler(@handHandler)
            @rightClickMenu.setMenu(@rightClickMenu.entityMenu)
            
    _updateMousePosition: (evt) ->
        [@mouseX, @mouseY] = Editors.getEvtOffset(evt)
        @_updateMouseGamePosition()
    _updateMouseGamePosition: ->
        [@mouseGameX, @mouseGameY] = SpaceConversion.Canvas.Game(@mouseX, @mouseY)
            
    brushPoint: ->
        if not Editors.toolsVisible
            return
        @brush.setPosition(@mouseGameX, @mouseGameY)
        if @brush.mode is 'none' or not @brush.tile or not Engine.level
            return
            
        tileType = if @brush.mode is 'draw' then Engine.level.getTileType(@brush.tile) else null
        
        @brush.forEachTile (r, c) =>
            oldTile = Engine.level.getTile(r, c)
            if tileType isnt oldTile
                @pendingDiff.push({r:r, c:c, tile: oldTile})
                Engine.level.setTile(r, c, tileType)
                
    _appendDiff: ->
        if @pendingDiff.length > 0
            @undoStack.push(@pendingDiff)
            @redoStack.length = 0
            @pendingDiff = []
    
    _revertDiff: (diff) ->
        reverse = []
        for i in [diff.length - 1..0] by -1
            change = diff[i]
            oldTile = Engine.level.getTile(change.r, change.c)
            Engine.level.setTile(change.r, change.c, change.tile)
            change.tile = oldTile
            reverse.push(change)
        return reverse
    
    undo: ->
        if @undoStack.length is 0
            return false
        @redoStack.push(@_revertDiff(@undoStack.pop()))
        
    redo: ->
        if @redoStack.length is 0
            return false
        @undoStack.push(@_revertDiff(@redoStack.pop()))
        
    clearUndoHistory: ->
        @undoStack.length = 0
        @redoStack.length = 0
        