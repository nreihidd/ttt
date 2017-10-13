window.CameraFocusTrait = new Hfoo.Trait
    traitName: 'cameraFocus'
    after: ['collider', 'spawn']
    hasTrait: (entityDescription) ->
        return 'collider' of entityDescription and 'cameraFocus' of entityDescription
    onAdd: (entity) ->
        if not @focus
            @focus = new Hfoo.CameraFocus(0, Hfoo.Engine.camera.centerBounds)
            Hfoo.Engine.camera.addFocus(@focus)
    onCreate: (entity) ->
        @focus.setCenter(entity.collider.rect.x, entity.collider.rect.y)
    onLogic: (entity) ->
        if not entity.isBeingDragged
            @focus.moveCenter(entity.collider.rect.x, entity.collider.rect.y)
        else
            @focus.clampCenter({
                left:   entity.collider.rect.x - Hfoo.gl.viewportWidth  / 2 + 50,
                right:  entity.collider.rect.x + Hfoo.gl.viewportWidth  / 2 - 50,
                bottom: entity.collider.rect.y - Hfoo.gl.viewportHeight / 2 + 50,
                top:    entity.collider.rect.y + Hfoo.gl.viewportHeight / 2 - 50
            })
