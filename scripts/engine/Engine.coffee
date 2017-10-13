### IMPORT
util/namespace
util/debug
util/utility
util/Dict2D
util/SpaceConversion
util/SpaceConversionUtil
util/Event
util/Observer
input/Keyboard
logic/Trait
traits/ColliderTrait
traits/SpriteTrait
traits/SpawnTrait
render/QuadIndices
render/ShaderProgram
render/Camera
render/CameraFocus
render/Texture
render/TileSheet
logic/LevelMap
logic/EdgeTable
logic/Tile
logic/LevelTileset
logic/Level
render/BackgroundColorRenderer
render/LevelRenderer
render/SpriteSheet
render/SpriteRenderer
render/Sprite
util/Rect
logic/Collider
editors/Editors
sound/Sound
###

#=========================================================
# Engine -- Singleton

declare "Engine", Engine = {}

gl = null

Engine.LOGIC_FPS = 60

Engine.create = ->
    delete @create
    
    # TODO: Reevaluate the usefulness of pausing globally vs fine-grained pausing
    #       of per entity.  Also add an entity interface/class?
    @paused = false
    
    @events =
        levelLoad:   new Event true
        logicEditor: new Event true
    
    @_initGL()

    # Level
    @level            = null
    @levelRenderer    = null
    
    # Camera
    @camera           = new Camera()
    @camera.setBounds {left: 0, right: 0, top: 0, bottom: 0}
    
    @renderers = []
    
    # Collider Manager
    @colliderManager = new ColliderManager()
    # Sprite Manager
    @spriteRenderer  = new SpriteRenderer(@camera)
    # Background Color Renderer
    @backgroundColorRenderer = new BackgroundColorRenderer(@camera)
    
    # Traits
    @entityManager = new EntityManager()
    @entityManager.defineTrait(ColliderTrait)
    @entityManager.defineTrait(SpriteTrait)
    @entityManager.defineTrait(DraggableTrait)
    @entityManager.defineTrait(SpawnTrait)

    # Observables
    @observables =
        level: new Observable(null)

    # Observers
    @observers =
        levelSize: new Observer =>
            @camera.setBounds(@level.bounds)
    
    Keyboard.registerHotkey 'Y', ->
        SoundManager.mute(not SoundManager.muted)
    
    Editors.init()
    
    @_start()

Engine.getLevelName = ->
    return @level?.name
    
Engine.setLevel = (name) ->
    if (@levelRenderer)
        @levelRenderer.destroy()
    @level = null
    @levelRenderer = null

    @entityManager.clear()
    onLoad = (level, status) =>
        if not level
            $("#error-message").text('Failed to load level: ' + status)
        else
            $("#error-message").text('')
            @level = level
            @levelRenderer = new LevelRenderer(@level, @camera)
            @colliderManager.level = @level
            @observers.levelSize.observe(@level.observables.size)
            @backgroundColorRenderer.setLevel(@level)
            @observables.level.update(@level)
            for entityDescription in @level.entityDescriptions
                @entityManager.createEntity(entityDescription)

    if not name
        Level.create(onLoad)
    else
        Level.load(name, onLoad)

Engine.restartLevel = ->
    entityDescriptions = @entityManager.getEntityDescriptions()
    @entityManager.clear()
    for entityDescription in entityDescriptions
        @entityManager.createEntity(entityDescription)

Engine.logic = ->
    @events.logicEditor.fire()
    if not (@paused or not @level)
        @entityManager.logic()
    @camera.update()
    debugInfo.CamX = @camera.pos[0].toFixed(2)
    debugInfo.CamY = @camera.pos[1].toFixed(2)

Engine.draw = ->
    @backgroundColorRenderer.draw()
    if @levelRenderer
        @levelRenderer.draw()
    for renderer in @renderers
        renderer.draw()
    @spriteRenderer.draw()

Engine.onResize = ->
    $canvas = $(gl.viewportCanvas)
    canvas = $canvas[0]
    gl.viewportWidth  = $canvas.width()
    gl.viewportHeight = $canvas.height()
    canvas.width = gl.viewportWidth
    canvas.height = gl.viewportHeight
    gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight)
    if @level
        @camera.setBounds(@level.bounds)

Engine._initGL = ->
    delete @_initGL

    $canvas = $("#main-view")
    canvas = @canvas = $canvas[0]
    gl = WebGLUtils.setupWebGL canvas, {depth: false, alpha: false}
    declare "gl", gl

    window.onresize = =>
         @onResize()
    
    init = =>
        gl.viewportCanvas = canvas
        @onResize()
        gl.clearColor 0, 0.5, 0, 1
        gl.clear gl.COLOR_BUFFER_BIT
        gl.enable gl.BLEND
        gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
        gl.disable gl.DEPTH_TEST
        gl.disable gl.CULL_FACE

    init()

Engine._start = ->
    delete @_start;
    
    drawFPS  = fpsCounter()
    logicFPS = fpsCounter()

    debugInfo.UPS = 0
    debugInfo.FPS = 0
    
    logic = =>
        fps = logicFPS()
        if fps isnt false
            debugInfo.UPS = fps
        @logic()
    
    logicFrames = 0.0
    timeLast = getTime()
    doLogicFrames = ->
        timeNow = getTime()
        timeDelta = timeNow - timeLast
        logicFrames += timeDelta / (1000 / Engine.LOGIC_FPS)
        if logicFrames > Engine.LOGIC_FPS * 2
            # If more than 2 seconds behind, just reset
            logicFrames = 0
        while logicFrames > 1
            logic()
            logicFrames -= 1
        timeLast = timeNow
    
    draw = =>
        fps = drawFPS()
        if fps isnt false
            debugInfo.FPS = fps
            
        gl.clearColor(0, 0, 0, 1)
        gl.clear(gl.COLOR_BUFFER_BIT)
        
        @draw()
    
    onAnimFrame = ->
        doLogicFrames()
        draw()
        requestAnimFrame(onAnimFrame, gl.viewportCanvas)

    # setInterval(doLogicFrames, 100)
    onAnimFrame()
