#=========================================================
# namespace

__api = {}

((name) ->
    if window[name] is undefined
        window[name] = __api
    else
        throw 'window[#{name}] is already defined'
)("Hfoo")

functionHeader = ///
    function
    (?:/\*.*?\*/ | \s)+
    ([$_A-Za-z][$_A-za-z0-9]*)
///

getFunctionName = (func) ->
    if func.name isnt undefined
        return func.name
    else
        match = functionHeader.exec(func.toString())
        if match
            return match[1]
    return ''
        
# if name is not passed, and obj is a function
#   this will attempt to parse out the function's name
# declare([name,] obj)
declare = (name, obj) ->
    if name isnt undefined and obj is undefined
        obj = name
        name = ''
        if typeof(obj) is "function"
            name = getFunctionName(obj)
    if name is ''
        throw 'Cannot use the empty string as a name'
    if name of __api
        throw "#{name} has already been exported!"
    __api[name] = obj
    return obj
