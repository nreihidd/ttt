declare class DataNode
    constructor: (@value, @setter) ->
        @updateEvent = new Event true
    set: ->
        if @setter.apply(this, arguments) is false
            return false
        @updateEvent.fire(this)
        return true

class IntermediateDataLink
    constructor: (base, path, callback) ->
        @node = base[path[0]]
        if not (@node instanceof DataNode)
            throw base.toString() + "." + path[0] + " is not a DataNode"
        if path.length is 1
            @listenId = @node.updateEvent.listen(callback)
            callback(@node)
        else
            subpath = path.slice(1)
            onUpdate = =>
                @childLink?.destroy()
                @childLink = new DataLink(@node.value, subpath, callback)
            @listenId = @node.updateEvent.listen(onUpdate)
            onUpdate()

    destroy: ->
        @childLink?.destroy()
        @node?.updateEvent.forget(@listenId)

declare class DataLink
    constructor: ->
        if arguments.length < 3
            throw "Need at least 3 arguments to create a data link"
        base = arguments[0]
        path = Array.prototype.slice.call(arguments, 1, arguments.length - 1)
        onUpdate = arguments[arguments.length - 1]

        @link = new IntermediateDataLink base, path, (node) =>
            @node = node
            onUpdate(@get())

    get: ->
        return @node.value
    set: ->
        return @node.set.apply(@node, arguments)

    destroy: ->
        @link.destroy()