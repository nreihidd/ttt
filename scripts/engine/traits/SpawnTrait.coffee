declare "SpawnTrait", SpawnTrait = new Trait
    traitName: 'spawn'
    after: ['sprite', 'draggable', 'collider']

    applyDefaults: (properties) ->
        defaults = {
            x:  TraitProperties.number(properties.x, 0)
            y:  TraitProperties.number(properties.y, 0)
        }

        properties.x = defaults.x
        properties.y = defaults.y

        return defaults

    onLogic: (entity) ->
        entity.spawnSprite.logic()

    onCreate: (entity) ->
        if entity.collider
            entity.collider.rect.x = entity.entityDescription.spawn.x
            entity.collider.rect.y = entity.entityDescription.spawn.y
        else if entity.sprite
            entity.sprite.position[0] = entity.entityDescription.spawn.x
            entity.sprite.position[1] = entity.entityDescription.spawn.y

    onAdd: (entity, properties) ->
        if entity.sprite
            entity.spawnSprite = new Sprite(entity.sprite.spriteSheet.url, entity.sprite.size)
        else
            entity.spawnSprite = new Sprite("sprites/question-mark.json", [16, 16])

        entity.spawnSprite.alpha = 0.25
        entity.spawnSprite.position[0] = properties.x
        entity.spawnSprite.position[1] = properties.y
        Engine.spriteRenderer.add(entity.spawnSprite)

    onUpdate: (entity, properties) ->
        sprite = entity.sprite
        spawnSprite = entity.spawnSprite
        changeSpritesheetURL = undefined

        if not sprite
            changeSpritesheetURL = "sprites/question-mark.json"
        else if sprite
            changeSpritesheetURL = sprite.spriteSheet.url
            spawnSprite.size[0] = sprite.size[0]
            spawnSprite.size[1] = sprite.size[1]

        if changeSpritesheetURL != spawnSprite.spriteSheet.url
            Engine.spriteRenderer.remove(spawnSprite)
            spawnSprite.setSpritesheetURL(changeSpritesheetURL)
            Engine.spriteRenderer.add(spawnSprite)

        spawnSprite.position[0] = properties.x
        spawnSprite.position[1] = properties.y

    onRemove: (entity) ->
        if entity.spawnSprite
            Engine.spriteRenderer.remove(entity.spawnSprite)
            delete entity.spawnSprite

