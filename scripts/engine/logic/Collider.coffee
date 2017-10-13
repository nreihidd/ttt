#=========================================================
# Collider

declare class Collider
    constructor: (@rect) ->
        @velocity = [0, 0]
        @grounded = false
        @contacts = {bottom: [], top: [], left: [], right: []}
        @skip = false

#=========================================================
# ColliderManager

declare class ColliderManager
    constructor: (@level) ->
        ;
    
    logic: (objects) ->
        for obj in objects
            @_moveCollider(obj.collider)
        for obj in objects
            @_updateContacts(obj.collider)
        
    getCollidersAtPoint: (x, y) ->
        results = []
        for obj in ColliderTrait.objects
            if obj.collider.rect.containsPoint(x, y)
                results.push(obj)
        return results
        
    ###
     *  Given tile coordinates and object bounds, return the bounds
     *  of the collision if it exists.
    ###
    
    transform = [
        (x, y) -> return [ x,  y]
        (x, y) -> return [ y, -x]
        (x, y) -> return [-x, -y]
        (x, y) -> return [-y,  x]
        (x, y) -> return [ x, -y]
        (x, y) -> return [ y,  x]
        (x, y) -> return [-x,  y]
        (x, y) -> return [-y, -x]
    ]

    applyBoundsTransform = (bounds, rotationData) ->
        x = (bounds.left + bounds.right - Level.TILE_SIZE) / 2
        y = (bounds.bottom + bounds.top - Level.TILE_SIZE) / 2
        [x, y] = transform[rotationData.flags](x, y)
        x += Level.TILE_SIZE / 2
        y += Level.TILE_SIZE / 2

        hwidth  = (bounds.right - bounds.left) / 2
        hheight = (bounds.top - bounds.bottom) / 2
        if (rotationData.flags & 1) isnt 0
            [hheight, hwidth] = [hwidth, hheight]

        bounds.left   = x - hwidth
        bounds.right  = x + hwidth
        bounds.top    = y + hheight
        bounds.bottom = y - hheight

    tileCollision: (r, c, bounds, direction) ->
        tile = @level.getTile(r, c)
        if not tile
            return false
        
        if not tile.collidesSide(Direction.opposite[direction])
            return false

        xOffset = c * Level.TILE_SIZE
        yOffset = r * Level.TILE_SIZE

        # Bring bounds into tile-local space (that is, with 0,0 being the bottom-left corner of the tile)
        localBounds =
            left:   bounds.left   - xOffset
            right:  bounds.right  - xOffset
            bottom: bounds.bottom - yOffset
            top:    bounds.top    - yOffset

        # Rotate the object's bounds to correctly line up with the height map
        # The bounds is currently in the rotated space (as it interacts with the rotated tile)
        # so we must "unrotate" it.
        applyBoundsTransform(localBounds, tile.rotationData.inverse)

        # Clip the bounds to the tile's bounds, which will always be 0,0 to 16,16
        localBounds = boundsIntersection(localBounds, Tile.LOCAL_BOUNDS, localBounds)
        if not localBounds
            return false

        # Create a separate bounds to find the actual area of collision
        collision = 
            left: null
            right: null
            bottom: null
            top: null

        low  = Math.floor(localBounds.left)
        high = Math.ceil(localBounds.right)

        for pixel in [low...high] by 1
            height = tile.height(pixel, false)
            # since localBounds is intersected with Tile.LOCAL_BOUNDS, localBounds.bottom will 
            # be >= 0 and so passing this 'if' also guarantees that height != 0
            if height > localBounds.bottom
                if collision.left is null
                    collision.left = pixel
                collision.right = pixel + 1
                # > and < treat null as 0, so the 'collision.top is null or ...' here is implicit,
                # as height must be > 0 to reach this point
                if height > collision.top
                    collision.top = height

        # If collision.top is not null then collision.right and collision.left are also not null
        if collision.top is null
            return false

        collision.bottom = localBounds.bottom
        # Clip the collision bounds back to the object/tile overlap
        collision = boundsIntersection(localBounds, collision, collision)
        if not collision
            return false

        # Rotate/flip the bounds to restore them to their proper place in the game world
        applyBoundsTransform(collision, tile.rotationData)
        collision.left   += xOffset
        collision.right  += xOffset
        collision.bottom += yOffset
        collision.top    += yOffset
        # TODO: Consider intersecting collision with bounds before returning to deal with rounding
        # errors in the transform back from local space.
        return collision

    tileCollisions: (bounds, direction) ->
        tileBounds =
            left:   Math.floor(bounds.left / Level.TILE_SIZE)
            right:  Math.ceil(bounds.right / Level.TILE_SIZE) - 1
            bottom: Math.floor(bounds.bottom / Level.TILE_SIZE)
            top:    Math.ceil(bounds.top / Level.TILE_SIZE) - 1
        
        collisionResult = null
        for r in [tileBounds.bottom..tileBounds.top] by 1
            for c in [tileBounds.left..tileBounds.right] by 1
                collision = @tileCollision(r, c, bounds, direction)
                if collision
                    if collisionResult
                        boundsUnion(collisionResult, collision, collisionResult)
                    else
                        collisionResult = collision
                        
        return collisionResult


    tileContact: (r, c, bounds) ->
        tile = @level.getTile(r, c)
        if not tile
            return false
        
        contact = []
        localBounds =
            left:   bounds.left   - c * Level.TILE_SIZE
            right:  bounds.right  - c * Level.TILE_SIZE
            bottom: bounds.bottom - r * Level.TILE_SIZE
            top:    bounds.top    - r * Level.TILE_SIZE

        edges = tile.edgeTable
        for side in Direction.directions
            sideValue = localBounds[side]
            if sideValue != Math.floor(sideValue)
                continue
            ranges = edges[side][sideValue]
            if not ranges
                continue
            axis = Direction.axis[side].other
            low  = localBounds[axis.low]
            high = localBounds[axis.high]
            for range in ranges
                if low < range[1] and high > range[0]
                    contact.push(side)
                    break

        return contact

    tileContacts: (bounds) ->
        # Finds all shared edges between the passed bounds and all tiles

        tileBounds =
            left:   Math.floor(bounds.left   / Level.TILE_SIZE)     - (if bounds.left   % Level.TILE_SIZE == 0 then 1 else 0)
            right:  Math.ceil(bounds.right   / Level.TILE_SIZE) - 1 + (if bounds.right  % Level.TILE_SIZE == 0 then 1 else 0)
            bottom: Math.floor(bounds.bottom / Level.TILE_SIZE)     - (if bounds.bottom % Level.TILE_SIZE == 0 then 1 else 0)
            top:    Math.ceil(bounds.top     / Level.TILE_SIZE) - 1 + (if bounds.top    % Level.TILE_SIZE == 0 then 1 else 0)
        
        contacts =
            bottom: []
            top:    []
            left:   []
            right:  []
        
        for r in [tileBounds.bottom..tileBounds.top] by 1
            for c in [tileBounds.left..tileBounds.right] by 1
                contact = @tileContact r, c, bounds
                if contact
                    for side in contact
                        contacts[side].push [r, c]
        
        return contacts

    _move: (collider, axis, v) ->
        if v is 0
            return 0
        
        # Find the direction
        direction;
        if axis is 'x'
            direction = if v < 0 then 'left' else 'right'
        else
            direction = if v < 0 then 'bottom' else 'top'
        
        opp = Direction.opposite[direction]
        bounds = collider.rect.toBounds()
        
        # Set up the collision bounds
        bounds[opp] = bounds[direction]
        bounds[direction] += v
        # bounds[opp] += Direction.unit[direction];
        
        # Find collisions
        collision = @tileCollisions(bounds, direction)
        amount = v
        if collision
            amount = collision[opp] - bounds[opp]
        
        # TODO: This can actually fire in rare cases.  What happens is
        # amount comes back as like 8e-16 when it should be 0.
        if amount * v < 0 # TODO: Remove this check eventually
            console.log("Error:")
            console.log({
               "direction": direction,
               "amount": amount,
               "v": v,
               "bounds": bounds,
               "collision": collision
            })
            return 0 # Something's screwed up above
        
        if direction of Direction.x
            collider.rect.translate amount, 0
        else
            collider.rect.translate 0, amount
        
        return amount

    @MAX_ITERATIONS = 1;

    _moveCollider: (collider) ->
        vx = collider.velocity[0]
        vy = collider.velocity[1]
        wasGrounded = collider.grounded
        collider.grounded = false
        
        debugInfo.VX = collider.velocity[0].toFixed(2)
        debugInfo.VY = collider.velocity[1].toFixed(2)
        
        if collider.skip
            collider.skip = false
            return
        
        if wasGrounded
            stepUp = @_move collider, 'y', 1
            vx -= @_move collider, 'x', vx
            stepDown = @_move collider, 'y', -2.1
            if stepDown < -2
                stepDown += @_move collider, 'y', -stepDown - 1
            vy = vy - stepUp + stepDown
        
        iterations = 0
        
        loop
            dx = @_move(collider, 'x', vx);
            dy = @_move(collider, 'y', vy);
            
            vx -= dx;
            vy -= dy;
            
            # updateDebugInfo("DX", dx.toFixed(2));
            # updateDebugInfo("DY", dy.toFixed(2));
            break unless (Math.abs(dx) > 0.1 or Math.abs(dy) > 0.1) and (++iterations < ColliderManager.MAX_ITERATIONS)

    _updateContacts: (collider) ->
        collider.contacts = @tileContacts collider.rect.toBounds()
        if collider.contacts.bottom.length > 0 and collider.velocity[1] <= 0
            collider.grounded = true
        debugInfo.Grounded = collider.grounded
        
        contactString = '';
        contactStringSide =
            bottom: 'v'
            top:    '^'
            left:   '<'
            right:  '>'
        for side of collider.contacts
            for i in collider.contacts[side]
                contactString += contactStringSide[side]
        
        # updateDebugInfo("Top", collider.rect.getTop().toFixed(2));
        debugInfo.PX = collider.rect.x.toFixed(4)
        debugInfo.PY = collider.rect.y.toFixed(4)
        debugInfo.Contacts = contactString

