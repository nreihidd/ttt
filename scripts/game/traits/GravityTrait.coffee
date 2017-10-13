window.GravityTrait = new Hfoo.Trait
    traitName: 'gravity'
    after: ['collider']

    hasTrait: (entityDescription) ->
        return 'collider' of entityDescription and 'gravity' of entityDescription

    applyDefaults: (properties) ->
        return {
            amount:  Hfoo.TraitProperties.number(properties.amount, 0)
        }

    onLogic: (entity) ->
        if not entity.collider.grounded
            entity.collider.velocity[1] += entity.gravity
        else
            if entity.collider.velocity[1] < -10
                Hfoo.SoundManager.playSound("land")
            entity.collider.velocity[1] = 0
    onAdd: (entity, properties) ->
        entity.gravity = properties.amount
    onUpdate: (entity, properties) ->
        entity.gravity = properties.amount
    onRemove: (entity) ->
        delete entity.gravity
