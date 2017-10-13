declare "SpriteTrait", SpriteTrait = new Trait
    traitName: 'sprite'
    after: ['collider']

    applyDefaults: (properties) ->
        return {
            url:    TraitProperties.url(properties.url,         "sprites/question-mark.json")
            width:  TraitProperties.number(properties.size?[0], 16)
            height: TraitProperties.number(properties.size?[1], 16)
        }

    onLogic: (entity) ->
        if entity.collider
            # Mirror the sprite depending on direction
            if entity.collider.velocity[0] > 0
                entity.sprite.scale[0] = -1
            else if entity.collider.velocity[0] < 0
                entity.sprite.scale[0] = 1
            entity.sprite.position[0] = Math.round(entity.collider.rect.x)
            entity.sprite.position[1] = Math.round(entity.collider.rect.y)
        entity.sprite.logic()

    onAdd: (entity, properties) ->
        entity.sprite = new Sprite(properties.url, [properties.width, properties.height])
        Engine.spriteRenderer.add(entity.sprite)
    onUpdate: (entity, properties) ->
        if properties.url isnt entity.sprite.spriteSheet.url
            Engine.spriteRenderer.remove(entity.sprite)
            entity.sprite.setSpritesheetURL(properties.url)
            Engine.spriteRenderer.add(entity.sprite)
        entity.sprite.size[0] = properties.width
        entity.sprite.size[1] = properties.height
    onRemove: (entity) ->
        Engine.spriteRenderer.remove(entity.sprite)
        delete entity.sprite

