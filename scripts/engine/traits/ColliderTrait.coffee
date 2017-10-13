declare "ColliderTrait", ColliderTrait = new Trait
    traitName: 'collider'
    before: ['sprite']

    applyDefaults: (properties) ->
        return {
            width:  TraitProperties.number(properties.size?[0], 16)
            height: TraitProperties.number(properties.size?[1], 16)
        }

    massLogic: (entities) ->
        Engine.colliderManager.logic(entities)
    onAdd: (entity, properties) ->
        rect = new Rect(0, 0, properties.width, properties.height)
        entity.collider = new Collider(rect)
    onUpdate: (entity, properties) ->
        entity.collider.rect.w = properties.width
        entity.collider.rect.h = properties.height
    onRemove: (entity) ->
        delete entity.collider