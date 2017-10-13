#=========================================================
# Keyboard -- Singleton

declare "Keyboard", Keyboard = {}

Keyboard.KEYS =
    arrowLeft:    37
    arrowUp:      38
    arrowRight:   39
    arrowDown:    40
    bracketOpen:  219
    bracketClose: 221
    tilde:        192
    
Keyboard.consumeKeystroke = ->
    @_consumeKeystroke = true
    
Keyboard._onKeyDown = (evt) ->
    @_consumeKeystroke = false
    
    key = evt.keyCode
    
    if not (key of @_down)
        @_down[key] = true
        @_pressed[key] = true
    
    if key of @_keyBindings
        if @_keyBindings[key]
            @_keyBindings[key](key, true, evt)
        @consumeKeystroke()

    if @_consumeKeystroke
        evt.stopPropagation()
        evt.preventDefault()

Keyboard._onKeyUp = (evt) ->
    @_consumeKeystroke = false
    
    key = evt.keyCode
    
    if key of @_down
        delete @_down[key]
    
    if key of @_keyBindings
        if @_keyBindings[key]
            @_keyBindings[key](key, false, evt)
        @consumeKeystroke()
        
    if @_consumeKeystroke
        evt.stopPropagation()
        evt.preventDefault()
    
Keyboard._toKeycode = (key) ->
    if typeof(key) is "string"
        return key.toUpperCase().charCodeAt(0)
    return key
    
Keyboard.isKeyDown = (key) ->
    key = @_toKeycode(key)
    return key of @_down
Keyboard.eatKeyPress = (key) ->
    key = @_toKeycode(key)
    if key of @_pressed
        delete @_pressed[key]
        return true
    return false
    
Keyboard.registerHotkey = (key, callback) ->
    @registerKey key, (k, down, evt) ->
        if down
            callback(k, down, evt)
    
Keyboard.registerKey = (key, callback) ->
    key = @_toKeycode(key)
    if key of @_keyBindings
        return false
    @_keyBindings[key] = callback
    return true

(->
    delete @create
        
    @_consumeKeystroke = false
    
    $(document).on "keydown keyup keypress", "input", (evt) ->
        evt.stopPropagation()
    $(document).on "keydown keyup keypress", "textarea", (evt) ->
        evt.stopPropagation()
    $(document).on "keydown", "textarea", (evt) ->
        if evt.keyCode is 9
            evt.preventDefault()
    # http://stackoverflow.com/questions/1738808/keypress-in-jquery-press-tab-inside-textarea-when-editing-an-existing-text
    # breaks textarea undo in chrome

    $(document).keydown @_onKeyDown.bind(this)
    $(document).keyup   @_onKeyUp.bind(this)
    
    @_keyBindings = {}
    @_down = {}
    @_pressed = {}
).apply(Keyboard)
