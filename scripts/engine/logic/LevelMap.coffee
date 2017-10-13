#=========================================================
# Level Map -- Singleton

declare "LevelMap", LevelMap =
    context: $("<canvas>")[0].getContext('2d')

    # lost the link
    # LevelMap.reverseBits = (b) ->
        # b = ((b * 0x0802 & 0x22110) | (b * 0x8020 & 0x88440)) * 0x10101 >> 16
        # return b & 0xFF
    
    drawLevel: (ctx, level) ->
        levelSize = level.getLevelSize()
        if not levelSize
            return
        
        ctx.canvas.width = levelSize[1]
        ctx.canvas.height = levelSize[0]
        imgData = ctx.getImageData(0, 0, levelSize[1], levelSize[0])
        
        level.forEachTile (row, col, tile) =>
            index = ((levelSize[0] - 1 - row) * imgData.width + col) * 4
            if tile
                rgba = tile.rgba
            else
                rgba = [0, 0, 255, 255]
            imgData.data[index + 0] = rgba[0]
            imgData.data[index + 1] = rgba[1]
            imgData.data[index + 2] = 255 - rgba[2]
            imgData.data[index + 3] = rgba[3]
            
        ctx.putImageData(imgData, 0, 0)
    
    levelToBase64PNG: (level) ->
        @drawLevel(@context, level)
        return @context.canvas.toDataURL("image/png")

    pngToImageData: (dataURL, callback) ->
        img = new Image()
        
        ctx = @context
        img.onload = ->
            ctx.canvas.width  = img.width
            ctx.canvas.height = img.height
            ctx.clearRect(0, 0, img.width, img.height)
            ctx.drawImage(img, 0, 0)
            
            callback(ctx.getImageData(0, 0,  img.width, img.height))

        img.src = dataURL
    
    pngToLevelData: (dataURL, callback) ->
        @pngToImageData dataURL, (imgData) ->
            levelData = {
                width: imgData.width
                height: imgData.height
            }
            
            data = []
            for row in [0...levelData.height] by 1
                data.push([])
                for col in [0...levelData.width] by 1
                    index = ((levelData.height - 1 - row) * levelData.width + col) * 4
                    if imgData.data[index + 2] == 0
                        data[row].push(null)
                    else
                        data[row].push([imgData.data[index], imgData.data[index + 1], 255 - imgData.data[index + 2]])
            
            levelData.data = data
            callback(levelData)
