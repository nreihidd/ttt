### IMPORT
Brush
BrushRenderer
DraggableTrait
Tooltip
RightclickMenu
LevelEditor
TilesetEditor
FreeCamera
EntityMenu
###

#=========================================================
# Editors -- Singleton

declare "Editors", Editors = {}

createElasticField = ($elem, callbacks) ->
    $elem.keydown (evt) ->
        if evt.which is 13
            evt.preventDefault()
            evt.stopPropagation()
            callbacks.set($elem.val())
            $elem.blur()
    $elem.blur (evt) ->
        $elem.val(callbacks.get())
    

Editors.init = ->
    delete @init

    @brush = new Brush()
    @brushRenderer = new BrushRenderer(@brush, Engine.camera)
    Engine.renderers.push(@brushRenderer)
    
    @tilesetEditor  = new TilesetEditor(@brush)
    @levelEditor    = new LevelEditor(Engine.canvas, @brush)
    
    @toolsVisible = true

    @freeCamera = new FreeCamera(Engine.canvas)
    
    Keyboard.registerHotkey Keyboard.KEYS.tilde, =>
        @setToolsVisible(not @toolsVisible)

    @observers =
        level: new Observer (level) =>
            if level is null
                @observers.levelBackgroundColor.forget()
                @observers.levelSize.forget()
                @observers.levelTileset.forget()
                @observers.levelRendererStatus.forget()
            else
                @levelEditor.clearUndoHistory()
                $("#level-change-name").val(Engine.getLevelName())
                @observers.levelBackgroundColor.observe(level.observables.backgroundColor)
                @observers.levelSize.observe(level.observables.size)
                @observers.levelTileset.observe(level.observables.tileset)
                @observers.levelRendererStatus.observe(Engine.levelRenderer.observables.status)
        levelSize: new Observer (levelSize) =>
            syncLevelSize()
            LevelMap.drawLevel(levelMapContext, Engine.level)
        levelBackgroundColor: new Observer (color) =>
            $("#level-background-color").val('#' + getBackgroundColor())
        levelTileset: new Observer (tileset) =>
            $("#level-tileset").val(tileset.url)
        levelRendererStatus: new Observer (status) =>
            if status is true
                @brushRenderer.tileSheet = Engine.levelRenderer.tileSheet
                @brushRenderer.dirty = true
        entityNameList: new Observer callLimiter(0, (list) =>
            $("#entity-list").empty()
            for entityName in list
                $("#entity-list").append(createEntityEntry(entityName)))

    createEntityEntry = (entityName) =>
        $option = $("<div>").text(entityName)
        $option.click =>
            @levelEditor.rightClickMenu.entityMenu.selectEntity(Engine.entityManager.getEntity(entityName))
            @levelEditor.rightClickMenu.entityMenu.showMenu()
        return $option

    @observers.entityNameList.observe(Engine.entityManager.observables.entityNameList)
    
    #==========
    # Level Size
    syncLevelSize = ->
        levelSize = Engine.level.getLevelSize()
        $("#level-size").val(levelSize[0] + ", " + levelSize[1])
    createElasticField $("#level-size"),
        get: ->
            levelSize = Engine.level.getLevelSize()
            return levelSize[0] + ", " + levelSize[1]
        set: (change) ->
            if matched = /([0-9]+),\s*([0-9]+)/.exec(change)
                Engine.level.setLevelSize(parseInt(matched[1]), parseInt(matched[2]))

    #==========
    # Change Background Color
    getBackgroundColor = ->
        hex = for color in Engine.level.backgroundColor[0..2]
            str = Math.floor(color * 255).toString(16)
            if str.length is 1 then '0' + str else str
        return hex.join('')
    createElasticField $("#level-background-color"),
        get: ->
            return '#' + getBackgroundColor()
        set: (change) ->
            if matched = /^#([0-9A-Fa-f]{6})$/.exec(change)
                color = for i in [0..2]
                    parseInt(matched[1][i*2] + matched[1][i*2+1], 16) / 255
                color.push(1)
                Engine.level.setBackgroundColor(color)

    #==========
    # Level Tileset
    createElasticField $("#level-tileset"),
        get: ->
            return Engine.level.tileset.url
        set: (change) ->
            Engine.level.setTilesetURL(change)

    #==========
    # Change Level
    createElasticField $("#level-change-name"),
        get: ->
            return Engine.getLevelName()
        set: (change) ->
            if change isnt ''
                Engine.setLevel(change)
                
    @observers.level.observe(Engine.observables.level)
        
    #==========
    # Pause
    togglePause = =>
        Engine.paused = not Engine.paused
        if Engine.paused
            $('#button-pause').addClass('active')
        else
            $('#button-pause').removeClass('active')
    Keyboard.registerHotkey('P', togglePause)
    $("#button-pause").click(togglePause)
    new Tooltip($("#button-pause")[0], {name: 'Pause', hotkey: 'P', description: "Pauses the game logic."})
        
    #==========
    # Listeners
    levelMapContext = $("#level-map")[0].getContext('2d')
        
    #==========
    # Save
    $("#level-save-submit").click (evt) ->
        if evt.which is 1
            saveLevel()
            
    saveLevel = ->
        levelName = $("#level-save-name").val()
        levelPassword = $("#level-save-password").val()
        levelData = Engine.level.toJSON()
        $.post('/submit-level', {
            "levelData": levelData
            "name": levelName
            "password": levelPassword
        }).success (data) ->
            $("#level-save-status").text(data)
            if data.indexOf('uccess') isnt -1
                Engine.setLevel(levelName)

    #==========
    # Restart Level
    $("#button-restart").click =>
        Engine.restartLevel()
    new Tooltip($("#button-restart")[0], {name: 'Restart Level', description: "Restarts the current level without reverting changes."})

    #==========
    # New Level
    $("#button-new-level").click =>
        if confirm("Are you sure you want to create an empty level?")
            Engine.setLevel(null)
    new Tooltip($("#button-new-level")[0], {name: 'New Level', description: "Creates a new, empty level."})

    #==========
    # Toggle Sections
    $(".sections .header").append($("<span class='toggle-indicator'></span>"))
    $(".sections .header").click ->
        $(this).toggleClass("minimized")
        $(this).next(".field").toggle()

Editors.setToolsVisible = (visible) ->
    if @toolsVisible is visible
        return
    @toolsVisible = visible
    if @toolsVisible
        $("#layout").show()
        $canvas = $("#main-view")
        $canvas.appendTo("#layout-middle")
        $("#no-tools").hide()
    else
        $("#no-tools").show()
        $canvas = $("#main-view")
        $canvas.appendTo("#no-tools")
        $("#layout").hide()
        @freeCamera.disable()
    Engine.onResize()
    
Editors.getEvtOffset = (e) ->
    if e.offsetX is undefined or e.offsetY is undefined
        return [
        	e.pageX - $(e.target).offset().left,
            e.pageY - $(e.target).offset().top
        ]
    else
        return [e.offsetX, e.offsetY]
        
Editors.getEvtAbsolute = (e) ->
    return [e.pageX, e.pageY]
