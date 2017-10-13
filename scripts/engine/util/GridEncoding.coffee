
declare "GridEncoding", GridEncoding =
    ###
        Maps scalar values to row, column coordinates and vice versa,
        to achieve the following mapping:
        
         0  1  4  9 ...
         3  2  5 10 ...
         8  7  6 11 ...
        15 14 13 12 ...
        ... etc
    ###

    encode: (r, c) ->
        m = Math.max(r, c) + 1
        return m * m - m - c + r
    decode: (e) ->
        b = Math.floor(Math.sqrt(e))
        m = b + 1
        mid = m * m - m
        if e <= mid
            return [b - mid + e, b]
        return [b, b + mid - e]
        