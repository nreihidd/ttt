#=========================================================
# Image Loading

window.loadImage = (url, onload) ->
    image = new Image()
    image.onload = ->
        onload(image)
        return
    image.src = url

#=========================================================
# Get Text

window.queryText = (url, callback) ->
    request = new XMLHttpRequest()
    request.onreadystatechange = ->
        if request.readyState is 4
            callback(request.responseText)
    request.open("GET", url + "?_" + Math.random(), true)
    request.send()

#=========================================================
# Get JSON

window.queryJSON = (url, callback) ->
    queryText url, (text) ->
        callback(JSON.parse(text))
        
window.loadJSON = (url, callback) ->
    jqr = $.ajax url,
        dataType: "json"
        success: (json) ->
            callback(json, 'success')
        error: (jqr, statusText) ->
            callback(null, statusText)

#=========================================================
# FPS and Time
    
window.getTime = () ->
    return new Date().getTime()
    
window.fpsCounter = () ->
    numFrames = 0
    time = getTime()
    
    return ->
        numFrames += 1
        timeElapsed = getTime() - time
        if timeElapsed > 1000
            value = Math.round(numFrames / timeElapsed * 1000)
            numFrames = 0
            time = getTime()
            return value
        return false

#=========================================================
# Clamp

window.clamp = (min, val, max) ->
    return Math.min(Math.max(min, val), max)

# min is inclusive, max is exclusive
# [min, max)
window.rolling = (min, val, max) ->
    size = max - min
    return min + (((val % size) + size) % size)

window.between = (min, val, max) ->
    return val >= min and val <= max


#=========================================================
# Object/Dictionary Utility

# From http:#stackoverflow.com/questions/2532218/pick-random-property-from-a-javascript-object
window.pickRandomProperty = (obj) ->
    result = undefined
    count = 0
    for prop of obj
        if Math.random() < 1/++count
           result = prop
    return result

window.copyObject = (o) ->
    r = {}
    for k of o
        if o.hasOwnProperty(k)
            r[k] = o[k]
    return r

window.applyDefaults = (obj, defaults) ->
    for k of defaults
        if defaults.hasOwnProperty(k) and not (k in obj)
            obj[k] = defaults[k]
    return obj

#=========================================================
# isArray

window.isArray = (v) ->
    return Object.prototype.toString.call(v) is '[object Array]'

#=========================================================
# callLimiter

# Limits calls to callback, through the returned function, to guarantee that
# the callback is NOT called until timeoutBetweenCalls milliseconds elapse
# from the last call to the returned function.
window.callLimiter = (timeoutBetweenCalls, callback) ->
    timeoutId = undefined
    nextArgs = null
    timeoutCallback = ->
        callback.apply(this, nextArgs)
        timeoutId = undefined
    return ->
        nextArgs = arguments
        if timeoutId isnt undefined
            window.clearTimeout(timeoutId)
        timeoutId = window.setTimeout(timeoutCallback, timeoutBetweenCalls)

#=========================================================
# cache
createCache = (props) ->
    cache = {}
    return ->
        key = props.key.apply(null, arguments)
        if not (key of cache)
            cache[key] = props.create.apply(null, arguments)
        return cache[key]