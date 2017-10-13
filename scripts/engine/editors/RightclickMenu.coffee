### IMPORT
BrushMenu
###

#=========================================================
# Right-click Menu

declare class RightclickMenu
    constructor: (canvas, brush) ->
        $canvas = $(canvas)
        $canvas.bind "contextmenu", (evt) =>
            return false
        $canvas.mouseup (evt) =>
            if evt.which == 3
                evt.stopPropagation()
                evt.preventDefault()
                # Without this setTimeout, if the menu opens underneath the mouse, that menu gets
                # right-clicked as well.
                window.setTimeout =>
                    @activeMenu?.toggleMenuAt(evt.pageX, evt.pageY)
                , 0
        $(document).mousedown (evt) =>
            if @activeMenu isnt null
                if $(evt.target).parents(@activeMenu.parentElement).length == 0 and
                   $(evt.target).filter(@activeMenu.parentElement).length  == 0
                    @activeMenu.hideMenu()

        @brushMenu = new BrushMenu(canvas, brush)
        @entityMenu = new EntityMenu()
        @activeMenu = null

    setMenu: (menu) ->
        if menu == @activeMenu
            return
        @activeMenu?.hideMenu()
        @activeMenu = menu
