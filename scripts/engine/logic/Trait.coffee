declare class Trait
    constructor: (properties) ->
        for name of properties
            this[name] = properties[name]

    # Override these to define a trait's behavior
    hasTrait: (entityDescription) ->
        return @traitName of entityDescription
    applyDefaults: (traitProperties) ->
        return traitProperties
    onAdd: (entity, traitProperties) ->
        # Add properties to entity to be used by this trait
    onUpdate: (entity, traitProperties) ->
        # Update properties of entity used by this trait
    onRemove: (entity) ->
        # Remove properties from entity added by this trait

    onCreate: (entity) ->
        # Occurs on entity creation
        # At level load, level restart, or creation through the editor
    # onLogic: (entity) ->
        # Occurs every frame
    massLogic: (entities) ->
        if @onLogic
            for entity in entities
                @onLogic(entity)

    # Do not override these methods
    removeEntity: (entity) ->
        index = @entities.indexOf(entity)
        if index is -1
            throw "Failed to remove entity '#{@entity.name}' from trait '#{@traitName}'"
        @entities.splice(index, 1)
        @onRemove(entity)
    addEntity: (entity) ->
        index = @entities.indexOf(entity)
        if index isnt -1
            throw "Failed to add entity '#{@entity.name}' to trait '#{@traitName}'"
        @entities.push(entity)
        @onAdd(entity, @applyDefaults(entity.entityDescription[@traitName]))
    updateEntity: (entity) ->
        index = @entities.indexOf(entity)
        if index is -1
            throw "Failed to update entity '#{@entity.name}' in trait '#{@traitName}'"
        @onUpdate(entity, @applyDefaults(entity.entityDescription[@traitName]))

declare "TraitProperties", TraitProperties = new class
    number: (value, defaultValue) ->
        if typeof(value) is 'number'
            return value
        if typeof(value) is 'string'
            try
                return parseFloat(value, 10)
            catch error
                return defaultValue
        return defaultValue
    string: (value, defaultValue) ->
        if typeof(value) is 'string'
            return value
        return defaultValue
    object: (value, defaultValue) ->
        if typeof(value) is 'object'
            return value
        return defaultValue
    array: (value, defaultValue) ->
        if isArray(value)
            return value
        return defaultValue
    name: (value, defaultValue) ->
        if typeof(value) is 'string'
            if /^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/.test(value)
                return value
        return defaultValue
    url: (value, defaultValue) ->
        if typeof(value) is 'string'
            if /^(?:\/?[a-z0-9.](?:[a-z0-9-.]*[a-z0-9.])?)*$/.test(value)
                return value
        return defaultValue

declare class EntityManager
    constructor: ->
        @traits = []
        @entities = {}
        @nextEntityId = 0

        @observables =
            entityNameList: new Observable([])
    
    orderTraits: ->
        traitSet = {}
        outgoingEdges = {} # holds outgoing edges
        incomingCount = {} # holds incoming edge count
        
        # Init data structures
        for trait in @traits
            traitSet[trait.traitName] = trait
            outgoingEdges[trait.traitName] = {}
            incomingCount[trait.traitName] = 0

        # Find all edges
        for trait in @traits
            if trait.before
                for other in trait.before
                    if other of traitSet
                        if not outgoingEdges[trait.traitName][other]
                            outgoingEdges[trait.traitName][other] = true
                            incomingCount[other] += 1
            if trait.after
                for other in trait.after
                    if other of traitSet
                        if not outgoingEdges[other][trait.traitName]
                            outgoingEdges[other][trait.traitName] = true
                            incomingCount[trait.traitName] += 1
                 
        # Find all sources
        sources = []
        for traitName of incomingCount
            if incomingCount[traitName] is 0
                sources.push(traitName)
                
        # Build trait ordering
        ordering = []
        while ordering.length < @traits.length
            if sources.length is 0
                console.log outgoingEdges, incomingCount, traitSet, sources, ordering
                throw "Cycle detected in trait ordering, aborting"
            source = sources.pop()
            ordering.push(traitSet[source])
            for other of outgoingEdges[source]
                incomingCount[other] -= 1
                if incomingCount[other] is 0
                    sources.push(other)
            
        @traits = ordering
        

    defineTrait: (trait) ->
        if trait.traitName is undefined
            throw "Trait missing required attribute"
        
        trait.entities = []
        
        @traits.push(trait)
        @orderTraits()

    logic: ->
        for trait in @traits
            trait.massLogic(trait.entities)

    # For debugging
    getTrait: (name) ->
        for trait in @traits
            if trait.traitName is name
                return trait
        return null

    _updateEntityNameList: ->
        value = []
        for entityName of @entities
            value.push(entityName)
        @observables.entityNameList.update(value)

    createEntity: (entityDescription) ->
        entity = {}
        if 'name' of entityDescription
            if entityDescription.name of @entities
                throw "Entity with name " + entityDescription.name + " already exists"
            else
                entity.name = entityDescription.name
        else
            while ("Entity" + @nextEntityId) of @entities
                @nextEntityId += 1
            entity.name = "Entity" + @nextEntityId++

        entity.entityDescription = entityDescription
        @entities[entity.name] = entity
        # Add traits
        for trait in @traits
            if trait.hasTrait(entityDescription)
                trait.addEntity(entity, entityDescription)
        # Call onCreate for each trait
        for trait in @traits
            if trait.hasTrait(entityDescription)
                trait.onCreate(entity)
        @_updateEntityNameList()
        return entity

    getEntity: (name) ->
        return @entities[name]

    removeEntity: (entity) ->
        if @entities[entity.name] != entity
            throw "Cannot remove entity, it was not added"
        for trait in @traits
            if trait.hasTrait(entity.entityDescription)
                trait.removeEntity(entity)
        delete @entities[entity.name]
        @_updateEntityNameList()

    updateEntity: (entity, entityDescription) ->
        if @entities[entity.name] != entity
            throw "Cannot update entity, it was not added"

        oldDescription = entity.entityDescription
        newDescription = entityDescription

        if newDescription.name != entity.name
            if newDescription.name of @entities
                throw "Entity with name " + newDescription.name + " already exists"
            else
                delete @entities[entity.name]
                entity.name = newDescription.name
                @entities[entity.name] = entity

        entity.entityDescription = newDescription

        for trait in @traits
            had = trait.hasTrait(oldDescription)
            has = trait.hasTrait(newDescription)
            # Remove trait
            if had and not has
                trait.removeEntity(entity)
            # Add trait
            else if not had and has
                trait.addEntity(entity, newDescription)
            # Update trait
            else if had and has
                trait.updateEntity(entity, newDescription)

    clear: ->
        # I believe this is legal
        # http://stackoverflow.com/questions/6081868/javascript-associative-array-modification-during-for-loop
        for entityName of @entities
            @removeEntity(@entities[entityName])

    getEntityDescriptions: ->
        result = []
        for entityName of @entities
            result.push(@entities[entityName].entityDescription)
        return result
    