declare "SpaceConversion", SpaceConversion = {}
SpaceConversion.GameLevelTile = {}
SpaceConversion.Game = {}
SpaceConversion.Tileset = {}
SpaceConversion.Tile = {}
SpaceConversion.WebGL = {}
SpaceConversion.TilePreview = {}
SpaceConversion.TilesetOverview = {}
SpaceConversion.Canvas = {}
SpaceConversion.GameLevelTile.Canvas = (x, y) ->
    return [
        Math.floor(( ( ( ( x * Level.TILE_SIZE ) - Engine.camera.pos[0] ) / (Engine.canvas.width / 2) ) + 1 ) * (Engine.canvas.width / 2)),
        Math.floor(( ( ( ( y * Level.TILE_SIZE ) - Engine.camera.pos[1] ) / (Engine.canvas.height / 2) ) + -1 ) * (-Engine.canvas.height / 2))
    ]

SpaceConversion.Game.Canvas = (x, y) ->
    return [
        Math.floor(( ( ( x - Engine.camera.pos[0] ) / (Engine.canvas.width / 2) ) + 1 ) * (Engine.canvas.width / 2)),
        Math.floor(( ( ( y - Engine.camera.pos[1] ) / (Engine.canvas.height / 2) ) + -1 ) * (-Engine.canvas.height / 2))
    ]

SpaceConversion.Canvas.WebGL = (x, y) ->
    return [
        ( x / (Engine.canvas.width / 2) ) - 1,
        ( y / (-Engine.canvas.height / 2) ) - -1
    ]

SpaceConversion.Tileset.TilesetOverview = (x, y) ->
    return [
        ( x * (Level.TILE_SIZE + 1) ) + 1,
        ( y * (Level.TILE_SIZE + 1) ) + 1
    ]

SpaceConversion.Canvas.Game = (x, y) ->
    return [
        ( ( ( x / (Engine.canvas.width / 2) ) - 1 ) * (Engine.canvas.width / 2) ) + Engine.camera.pos[0],
        ( ( ( y / (-Engine.canvas.height / 2) ) - -1 ) * (Engine.canvas.height / 2) ) + Engine.camera.pos[1]
    ]

SpaceConversion.Canvas.GameLevelTile = (x, y) ->
    return [
        Math.floor(( ( ( ( x / (Engine.canvas.width / 2) ) - 1 ) * (Engine.canvas.width / 2) ) + Engine.camera.pos[0] ) / Level.TILE_SIZE),
        Math.floor(( ( ( ( y / (-Engine.canvas.height / 2) ) - -1 ) * (Engine.canvas.height / 2) ) + Engine.camera.pos[1] ) / Level.TILE_SIZE)
    ]

SpaceConversion.WebGL.Game = (x, y) ->
    return [
        ( x * (Engine.canvas.width / 2) ) + Engine.camera.pos[0],
        ( y * (Engine.canvas.height / 2) ) + Engine.camera.pos[1]
    ]

SpaceConversion.GameLevelTile.Game = (x, y) ->
    return [
        x * Level.TILE_SIZE,
        y * Level.TILE_SIZE
    ]

SpaceConversion.TilePreview.Tile = (x, y) ->
    return [
        ( x - 1 ) * (Level.TILE_SIZE / TilesetEditor.TILE_PREVIEW_SIZE),
        ( y - 1 ) * (Level.TILE_SIZE / TilesetEditor.TILE_PREVIEW_SIZE)
    ]

SpaceConversion.WebGL.GameLevelTile = (x, y) ->
    return [
        Math.floor(( ( x * (Engine.canvas.width / 2) ) + Engine.camera.pos[0] ) / Level.TILE_SIZE),
        Math.floor(( ( y * (Engine.canvas.height / 2) ) + Engine.camera.pos[1] ) / Level.TILE_SIZE)
    ]

SpaceConversion.GameLevelTile.WebGL = (x, y) ->
    return [
        ( ( x * Level.TILE_SIZE ) - Engine.camera.pos[0] ) / (Engine.canvas.width / 2),
        ( ( y * Level.TILE_SIZE ) - Engine.camera.pos[1] ) / (Engine.canvas.height / 2)
    ]

SpaceConversion.Tile.TilePreview = (x, y) ->
    return [
        ( x / (Level.TILE_SIZE / TilesetEditor.TILE_PREVIEW_SIZE) ) + 1,
        ( y / (Level.TILE_SIZE / TilesetEditor.TILE_PREVIEW_SIZE) ) + 1
    ]

SpaceConversion.WebGL.Canvas = (x, y) ->
    return [
        Math.floor(( x + 1 ) * (Engine.canvas.width / 2)),
        Math.floor(( y + -1 ) * (-Engine.canvas.height / 2))
    ]

SpaceConversion.TilesetOverview.Tileset = (x, y) ->
    return [
        Math.floor(( x - 1 ) / (Level.TILE_SIZE + 1)),
        Math.floor(( y - 1 ) / (Level.TILE_SIZE + 1))
    ]

SpaceConversion.Game.GameLevelTile = (x, y) ->
    return [
        Math.floor(x / Level.TILE_SIZE),
        Math.floor(y / Level.TILE_SIZE)
    ]

SpaceConversion.Game.WebGL = (x, y) ->
    return [
        ( x - Engine.camera.pos[0] ) / (Engine.canvas.width / 2),
        ( y - Engine.camera.pos[1] ) / (Engine.canvas.height / 2)
    ]

