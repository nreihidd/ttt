window.TerminalVelocityTrait = new Hfoo.Trait
    traitName: 'terminalVelocity'
    after: ['gravity']
    
    hasTrait: (entityDescription) ->
        return 'collider' of entityDescription and 'terminalVelocity' of entityDescription

    applyDefaults: (properties) ->
        return {
            amount:  Hfoo.TraitProperties.number(properties.amount, 16)
        }

    onLogic: (entity) ->
        entity.collider.velocity[1] = clamp(-entity.terminalVelocity, entity.collider.velocity[1], entity.terminalVelocity)
    onAdd: (entity, properties) ->
        entity.terminalVelocity = properties.amount
    onUpdate: (entity, properties) ->
        entity.terminalVelocity = properties.amount
    onRemove: (entity) ->
        delete entity.terminalVelocity
