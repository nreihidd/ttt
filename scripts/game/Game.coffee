### IMPORT
traits/GravityTrait
traits/TerminalVelocityTrait
traits/ControlsTrait
traits/FallToTopTrait
traits/BonkHeadTrait
traits/CameraFocusTrait
traits/SimpleAiTrait
traits/AnimatorTrait
###

#=========================================================
# Game -- Singleton

window.Game = {}

Game.create = ->
    delete @create

    levelName = location.search
    newLevel  = levelName is "" or not /^\?\/.+$/.test(levelName)
    if newLevel
        levelName = null
    else
        levelName = levelName.substring(2)

    
    engine = Hfoo.Engine
    
    engine.create()
    engine.setLevel(levelName)
    
    # Traits
    engine.entityManager.defineTrait(GravityTrait)
    engine.entityManager.defineTrait(TerminalVelocityTrait)
    engine.entityManager.defineTrait(ControlsTrait)
    engine.entityManager.defineTrait(FallToTopTrait)
    engine.entityManager.defineTrait(BonkHeadTrait)
    engine.entityManager.defineTrait(CameraFocusTrait)
    engine.entityManager.defineTrait(SimpleAiTrait)
    engine.entityManager.defineTrait(AnimatorTrait)
    
    @observers =
        level: new Hfoo.Observer (level) =>
            if level
                history.replaceState(null, '', '?/' + level.name)

    @observers.level.observe(engine.observables.level)
    
    Hfoo.SoundManager.loadSoundGroup("jump", ["/sounds/jump.ogg", "/sounds/jump2.ogg"])
    Hfoo.SoundManager.loadSound("headBonk", "/sounds/headbonk.ogg")
    Hfoo.SoundManager.loadSound("land", "/sounds/land.ogg")
