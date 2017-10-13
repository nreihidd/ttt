declare class EdgeTable
    @createFromHeightMap: (heightmap) ->
        edges = {top: {}, right: {}, bottom: {}, left: {}}
        prevPoint = [0, 0]
        startPoint = [undefined, undefined]
        point = [undefined, undefined]

        heightmap = heightmap.concat([0])

        for height in heightmap
            point[0] = prevPoint[0]
            point[1] = height

            # Edge up, entity's right side
            if point[1] > prevPoint[1]
                @addEdge(edges, 'right', prevPoint[0], [prevPoint[1], point[1]])
            # Edge down, entity's left side
            else if point[1] < prevPoint[1]
                @addEdge(edges, 'left', prevPoint[0], [point[1], prevPoint[1]])
            # Otherwise edges are equal or something is NaN, either way add no edge

            if point[1] is 0
                # Edge left, back to the start
                if startPoint[0] isnt undefined
                    @addEdge(edges, 'top', 0, [startPoint[0], point[0]])

                    startPoint[0] = undefined
                    startPoint[1] = undefined

                prevPoint[0] += 1
                prevPoint[1] = 0
                continue
            else
                if startPoint[0] is undefined
                    startPoint[0] = prevPoint[0]
                    startPoint[1] = prevPoint[1]

            point[0] += 1
            # Edge right, entity's bottom side
            @addEdge(edges, 'bottom', point[1], [prevPoint[0], point[0]])

            prevPoint[0] = point[0]
            prevPoint[1] = point[1]

        return edges

    @rotateTable: (edges, rotationInfo) ->
        rotatedEdges = {top: {}, right: {}, bottom: {}, left: {}}
        for side of edges
            rotateSide = rotationInfo[side]
            rotatedSide = rotatedEdges[rotateSide] = {}
            for value of edges[side]
                if (side of Direction.x and rotationInfo.reversed) or
                   (side of Direction.y and rotationInfo.yreversed)
                    rotatedValue = Level.TILE_SIZE - value
                else
                    rotatedValue = value
                rotatedSide[rotatedValue] = []
                for range in edges[side][value]
                    if (side of Direction.y and rotationInfo.reversed) or
                       (side of Direction.x and rotationInfo.yreversed)
                        rotatedSide[rotatedValue].unshift([Level.TILE_SIZE - range[1], Level.TILE_SIZE - range[0]])
                    else
                        rotatedSide[rotatedValue].push(range)

        return rotatedEdges

    @addEdge: (edges, side, value, range) ->
        if not edges[side][value]
            edges[side][value] = []
        ranges = edges[side][value]

        # Extend the previous range if possible
        if ranges.length > 0 and ranges[ranges.length - 1][1] == range[0]
            ranges[ranges.length - 1][1] = range[1]
        # Otherwise add the new disjoint range
        else
            edges[side][value].push(range)