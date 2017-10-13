window.FallToTopTrait = new Hfoo.Trait
    traitName: 'fallToTop'
    after: ['terminalVelocity']
    hasTrait: (entityDescription) ->
        return 'collider' of entityDescription and 'fallToTop' of entityDescription
    onLogic: (entity) ->
        if entity.collider.rect.getTop() < 0
            entity.collider.rect.setBottom(Hfoo.Engine.level.size[1])
            entity.collider.rect.x = clamp(0, entity.collider.rect.x, Hfoo.Engine.level.size[0])
