#=========================================================
# Entity Menu

declare class EntityMenu
    constructor: ->
        @_visible = false
        @parentElement = "#entity-json-position"
        @entity = null

        if false
            timeoutId = undefined
            $("#entity-json-text").keyup (evt) =>
                if timeoutId isnt undefined
                    window.clearTimeout(timeoutId)
                timeoutId = window.setTimeout( =>
                    timeoutId = undefined
                    @updateEntitySpawnData()
                , 2000)

        $("#entity-update").click (evt) =>
            @updateEntitySpawnData()
        $("#entity-delete").click (evt) =>
            if @entity
                try
                    Engine.entityManager.removeEntity(@entity)
                    @entity = null
                    $("#entity-json-text").val('')
                catch message
                    $("#entity-parse-error-message").text(message)
        $("#entity-restart").click (evt) =>
            if @entity
                Engine.entityManager.removeEntity(@entity)
                try
                    @entity = Engine.entityManager.createEntity(@entity.entityDescription)
                catch message
                    $("#entity-parse-error-message").text(message)
        $("#entity-create").click (evt) =>
            entityDescription = @parseTextarea()
            if entityDescription
                try
                    @entity = Engine.entityManager.createEntity(entityDescription)
                catch message
                    $("#entity-parse-error-message").text(message)

        @parseError = undefined
        $("#entity-parse-error-message").click (evt) =>
            if @parseError
                textarea = $("#entity-json-text")[0]
                textarea.focus()
                textarea.setSelectionRange(@parseError.offset, @parseError.offset)
    
    quote: (s) ->
        return '"' + s.
        replace(/\\/g, '\\\\').
        replace(/"/g, '\\"').
        replace(/\x08/g, '\\b').
        replace(/\t/g, '\\t').
        replace(/\n/g, '\\n').
        replace(/\f/g, '\\f').
        replace(/\r/g, '\\r').
        replace(/[\x00-\x07\x0B\x0E-\x1F\x80-\uFFFF]/g, escape) + '"'

    stringifyJSONless: (indentation, object) ->
        if object is null
            return 'null'
        else if typeof object is 'object'
            if isArray(object)
                value = ''
                for item in object
                    if value isnt ''
                        value += ' '
                    value += @stringifyJSONless('', item)
                return '[' + value + ']'
            else
                value = ''
                for prop of object
                    name = prop
                    if not /^[_A-Za-z][_A-Za-z0-9]*$/.test(name)
                        name = @quote(name)
                    if value is ''
                        if indentation is ''
                            value = ''
                        else
                            value += '\n' + indentation + '{'
                    else
                        value += '\n' + indentation
                    value += prop + ' ' + @stringifyJSONless(indentation + '  ', object[prop])
                if value == ''
                    return '{}'
                if indentation is ''
                    return value
                return value + '}'
        else if typeof object is "number"
            return object + ''
        else if typeof object is "string"
            return @quote(object)
        else
            console.error({message: "Object not JSONless-able", object: object})
            throw "Object not JSONless-able"

    selectEntity: (@entity) ->
        if @entity
            $("#entity-json-text").val(@stringifyJSONless('', @entity.entityDescription))
        else
            $("#entity-json-text").val(@stringifyJSONless('', {name: "new_entity"}))

    parseTextarea: ->
        try
            entityDescription = JSONless.parse($("#entity-json-text").val())
            $("#entity-parse-error-message").text('')
            $("#entity-parse-success-message").text('Parsed successfully!').show().fadeOut(2000)
            @parseError = undefined
            return entityDescription
        catch error
            $("#entity-parse-error-message").text(error.message)
            @parseError = error
        return undefined

    updateEntitySpawnData: ->
        entityDescription = @parseTextarea()

        if entityDescription and @entity
            try
                Engine.entityManager.updateEntity(@entity, entityDescription)
            catch message
                $("#entity-parse-error-message").text(message)
    
    hideMenu: ->
        if @_visible
            $("#entity-parse-success-message").hide()
            $("#entity-json-position").hide()
            @_visible = false
    
    toggleMenuAt: (x, y) ->
        @_visible = not @_visible
        if @_visible
            entities = DraggableTrait.getEntitiesAtPoint(Editors.levelEditor.mouseGameX, Editors.levelEditor.mouseGameY)
            if entities.length > 0
                @selectEntity(entities[0])
            else
                @selectEntity(null)
            $("#entity-json-position").show().css({
                left: x,
                top:  y
            })
            [dx, dy] = getDisplacementIntoViewport($("#entity-tools"))
            if dx != 0 or dy != 0
                $("#entity-json-position").css({
                    left: x + dx,
                    top:  y + dy
                })
        else
            $("#entity-json-position").hide()

    showMenu: ->
        if not @_visible
            @_visible = true
            x = Math.floor(window.innerWidth / 2)
            y = Math.floor(window.innerHeight / 2)
            $("#entity-json-position").show().css({
                left: x,
                top:  y
            })
            [dx, dy] = getDisplacementIntoViewport($("#entity-tools"))
            if dx != 0 or dy != 0
                $("#entity-json-position").css({
                    left: x + dx,
                    top:  y + dy
                })

