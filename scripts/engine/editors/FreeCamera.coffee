declare class FreeCamera
    constructor: (canvas) ->
        @focus = new CameraFocus(1, Engine.camera.levelBounds)
        @offset = [0, 0]
        @enabled = false

        #==========
        # Toggle Camera Mode
        toggleCameraMode = =>
            if not @enabled
                @enable()
            else
                @disable()
        Keyboard.registerHotkey('Q', toggleCameraMode)
        $("#button-camera").click(toggleCameraMode)
        new Tooltip($("#button-camera")[0], {name: 'Free Camera', hotkey: 'Q', description: "Enables the free camera.  Middle mouse drag to move."})

        $canvas = $(canvas)
        @mousePressed = false
        $canvas.mousedown (evt) =>
            if not @enabled and evt.which == 2 and Editors.toolsVisible
                @enable()

            if evt.which == 2 and @enabled
                [mouseX, mouseY] = Editors.getEvtOffset(evt)
                @mousePressed = true
                $canvas.addClass('panning')
                @startDrag(mouseX, mouseY)

        $canvas.mouseup (evt) =>
            if evt.which == 2 and @mousePressed
                @mousePressed = false
                $canvas.removeClass('panning')
        $(document).mouseup (evt) =>
            if evt.which == 2 and @mousePressed
                @mousePressed = false
                $canvas.removeClass('panning')
        $canvas.mousemove (evt) =>
            if @mousePressed
                [mouseX, mouseY] = Editors.getEvtOffset(evt)
                @moveDrag(mouseX, mouseY)
        $canvas.mouseover (evt) =>
            if @mousePressed
                [mouseX, mouseY] = Editors.getEvtOffset(evt)
                @startDrag(mouseX, mouseY)

        @enable = ->
            if not @enabled
                @focus.setCenter(Engine.camera.pos[0], Engine.camera.pos[1])
                Engine.camera.addFocus(@focus)
                @enabled = true
                $('#button-camera').addClass('active')
        @disable = ->
            if @enabled
                Engine.camera.removeFocus(@focus)
                @mousePressed = false
                $canvas.removeClass('panning')
                @enabled = false
                $('#button-camera').removeClass('active')

    startDrag: (x, y) ->
        @offset[0] = @focus.pos[0] + x
        @offset[1] = @focus.pos[1] - y
    moveDrag: (x, y) ->
        @focus.setCenter(@offset[0] - x, @offset[1] + y)