#=========================================================
# SoundManager

declare "SoundManager", SoundManager = new class
    constructor: ->
        @toLoad = []
        @_sm2ready = false
        @soundGroups = {}
        @muted = true

    _ready: ->
        @_sm2ready = true
        for obj in @toLoad
            @loadSound(obj.name, obj.url)
        @toLoad = []
        @mute(@muted)

    mute: (bool) ->
        @muted = bool
        if @_sm2ready
            if @muted
                soundManager.mute()
            else
                soundManager.unmute()

    loadSound: (name, url) ->
        return
        if @_sm2ready
            soundManager.createSound({
                'id': name
                'url': url
            })
        else
            @toLoad.push({'name': name, 'url': url})

    playSound: (name) ->
        return
        if not @_sm2ready
            return
        if name of @soundGroups
            index = Math.floor(Math.random() * @soundGroups[name])
            soundManager.play(name + '_group' + index)
        else
            soundManager.play(name)

    loadSoundGroup: (name, urls) ->
        return
        @soundGroups[name] = urls.length
        id = 0
        for url in urls
            @loadSound(name + '_group' + id++, url)
            
soundManager.url = '/sounds/soundmanager2/'
soundManager.onready ->
    SoundManager._ready()
