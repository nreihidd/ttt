declare "DraggableTrait", DraggableTrait = new Trait
    traitName: 'draggable'
    before: ['collider']
    
    draggables: []
    dragging: []
    needUpdate: false
    
    # debug value
    lastDragged: null

    hasTrait: (entityDescription) ->
        return 'spawn' of entityDescription or ('collider' of entityDescription and 'sprite' of entityDescription)
    
    massLogic: (entities) ->
        for dragEntry in @dragging
            dragEntry.entry.disableMovement?()
        if @needUpdate
            for dragEntry in @dragging
                dragEntry.entry.move(dragEntry.offset[0] + @x, dragEntry.offset[1] + @y)
            @needUpdate = false

    onAdd: (entity, properties) ->
        entity.dragEntries = []
        entity.isBeingDragged = false

        if 'collider' of entity.entityDescription and 'sprite' of entity.entityDescription
            entry = 
                containsPoint: (x, y) =>
                    return @spriteContainsPoint(entity.sprite, x, y)
                getOffset: (x, y) =>
                    return [entity.collider.rect.x - x, entity.collider.rect.y - y]
                move: (x, y) =>
                    entity.collider.rect.x = x
                    entity.collider.rect.y = y
                setDragStatus: (bool) ->
                    entity.isBeingDragged = bool
                disableMovement: ->
                    entity.collider?.skip = true
                entity: entity
            entity.dragEntries.push(entry)
            @draggables.push(entry)
        
        if 'spawn' of entity.entityDescription
            entry = 
                containsPoint: (x, y) =>
                    return @spriteContainsPoint(entity.spawnSprite, x, y)
                getOffset: (x, y) =>
                    return [entity.entityDescription.spawn.x - x, entity.entityDescription.spawn.y - y]
                move: (x, y) =>
                    entity.entityDescription.spawn.x = x
                    entity.entityDescription.spawn.y = y
                    entity.spawnSprite.position[0] = x
                    entity.spawnSprite.position[1] = y
                entity: entity
            entity.dragEntries.push(entry)
            @draggables.push(entry)

    onRemove: (entity) ->
        for entry in entity.dragEntries
            @draggables.splice(@draggables.indexOf(entry), 1)
            index = @dragging.indexOf(entry)
            if index != -1
                @dragging.splice(index, 1)
        delete entity.isBeingDragged
        delete entity.dragEntries

    onUpdate: (entity, properties) ->
        @onRemove(entity)
        @onAdd(entity, properties)

    spriteContainsPoint: (sprite, x, y) ->
        if not sprite
            return false
        sx  = sprite.position[0]
        sy  = sprite.position[1]
        shw = sprite.size[0] / 2
        shh = sprite.size[1] / 2
        return between(sx - shw, x, sx + shw) and between(sy - shh, y, sy + shh)

    anythingAtPoint: (x, y) ->
        for entry in @draggables
            if entry.containsPoint(x, y)
                return true
        return false
    getEntitiesAtPoint: (x, y) ->
        result = []
        for entry in @draggables
            if entry.containsPoint(x, y)
                result.push(entry.entity)
        return result
    getEntriesAtPoint: (x, y) ->
        result = []
        for entry in @draggables
            if entry.containsPoint(x, y)
                result.push(entry)
        return result

    isDragging:  false
    isHand:      false
    isMouseDown: false
    mouseMove: (@x, @y) ->
        if not @isMouseDown and not @isDragging
            hovering = false
            if @anythingAtPoint(@x, @y)
                hovering = true
            if not @isHand and hovering
                @isHand = true
                $(Engine.canvas).addClass('hand')
            else if @isHand and not hovering
                @isHand = false
                $(Engine.canvas).removeClass('hand')
        else if @isDragging
            @needUpdate = true

    mouseDown: (@x, @y) ->
        @dragging = []
        for entry in @getEntriesAtPoint(@x, @y)
            entry.setDragStatus?(true)
            @dragging.push({entry: entry, offset: entry.getOffset(@x, @y)})
        @isDragging = @dragging.length > 0
        if @isDragging
            @lastDragged = @dragging
            @isHand = true
            $(Engine.canvas).addClass('hand')
            $(Engine.canvas).addClass('dragging')
        @isMouseDown = true

    mouseUp: ->
        for dragEntry in @dragging
            dragEntry.entry.setDragStatus?(false)
        @dragging = []
        @isDragging = false
        @isMouseDown = false
        $(Engine.canvas).removeClass('dragging')
        @mouseMove(@x, @y)

    mouseDisable: ->
        if @isMouseDown
            @mouseUp(@x, @y)
        if @isHand
            @isHand = false
            $(Engine.canvas).removeClass('hand')


