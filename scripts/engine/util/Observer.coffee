declare class Observable
    constructor: (@value) ->
        @evt = new Event true
    update: (@value) ->
        @evt.fire(@value)

declare class Observer
    constructor: (@onUpdate) ->
        @target = null
        @listenId = undefined

    observe: (@target) ->
        @forget()
        @listenId = @target.evt.listen(@onUpdate)
        @onUpdate(@target.value)
    forget: ->
        @target?.evt.forget(@listenId)
    get: ->
        return @target?.value