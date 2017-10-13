window.SimpleAiTrait = new Hfoo.Trait
    traitName: 'simpleAI'
    after: ['collider']
    onLogic: (entity) ->
        if entity.collider.rect.x is entity.simpleAI.lastX
            entity.collider.velocity[0] *= -1
        # if entity.collider.contacts.left.length > 0 or entity.collider.contacts.right.length > 0
            # entity.collider.velocity[0] *= -1
        entity.simpleAI.lastX = entity.collider.rect.x
        entity.simpleAI.lastY = entity.collider.rect.y
    onAdd: (entity, properties) ->
        entity.simpleAI =
            lastX: entity.collider.rect.x
            lastY: entity.collider.rect.y
        entity.collider.velocity[0] = properties.speed ? 0
    onUpdate: (entity, properties) ->
        entity.collider.velocity[0] = properties.speed ? 0
    onRemove: (entity) ->
        delete entity.simpleAI
        
