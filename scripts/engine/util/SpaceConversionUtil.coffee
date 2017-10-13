
SpaceConversion.bounds = (converter, bounds) ->
    value = {}
    [value.left, value.bottom] = converter(bounds.left, bounds.bottom)
    [value.right, value.top]   = converter(bounds.right, bounds.top)
    return value