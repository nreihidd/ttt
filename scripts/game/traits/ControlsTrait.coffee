window.ControlsTrait = new Hfoo.Trait
    traitName: 'controls'
    before: ['collider']
    hasTrait: (entityDescription) ->
        return 'collider' of entityDescription and 'controls' of entityDescription

    applyDefaults: (properties) ->
        return {
            keys:       Hfoo.TraitProperties.object(properties.keys, {})
            speed:      Hfoo.TraitProperties.number(properties.speed, 1)
            jumpSpeed:  Hfoo.TraitProperties.number(properties.jumpSpeed, 0)
            groundAcc:  Hfoo.TraitProperties.number(properties.groundAcc, Infinity)
            airAcc:     Hfoo.TraitProperties.number(properties.airAcc, Infinity)
        }

    onAdd: (entity, properties) ->
        entity.keyMapping = {}
        for command, key of properties.keys
            Hfoo.Keyboard.registerKey(key, null)
            entity.keyMapping[command] = key
        entity.speed = properties.speed
        entity.jumpSpeed = properties.jumpSpeed
        entity.groundAcceleration = properties.groundAcc
        entity.airAcceleration = properties.airAcc
    onUpdate: (entity, properties) ->
        entity.keyMapping = {}
        for command, key of properties.keys
            Hfoo.Keyboard.registerKey(key, null)
            entity.keyMapping[command] = key
        entity.speed = properties.speed
        entity.jumpSpeed = properties.jumpSpeed
        entity.groundAcceleration = properties.groundAcc
        entity.airAcceleration = properties.airAcc
    onRemove: (entity) ->
        delete entity.keyMapping
        delete entity.speed
        delete entity.jumpSpeed
        delete entity.groundAcceleration
        delete entity.airAcceleration
            
    onLogic: (entity) ->
        if entity.collider.grounded
            speed = entity.groundAcceleration
        else
            speed = entity.airAcceleration

        vx = 0
        heldLeft = Hfoo.Keyboard.isKeyDown(entity.keyMapping.left)
        heldRight = Hfoo.Keyboard.isKeyDown(entity.keyMapping.right)
        if heldLeft and not heldRight
            vx -= speed
        if heldRight and not heldLeft
            vx += speed
        if vx == 0
            vx = clamp(-speed, -entity.collider.velocity[0], speed)

        entity.collider.velocity[0] = clamp(-entity.speed, entity.collider.velocity[0] + vx, entity.speed)
        if Hfoo.Keyboard.eatKeyPress(entity.keyMapping.jump)
            if entity.collider.grounded
                entity.collider.velocity[1] = entity.jumpSpeed
                Hfoo.SoundManager.playSound("jump")
