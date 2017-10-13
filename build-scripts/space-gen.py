import types

className = "SpaceConversion"

# A formula is an arithmetic operation list
# An operation is represented by a 3-tuple
#  op, args, next
# operation tree, inner is the operation performed
# previously
# the chain is terminated by a 'None' inner
def containsFloor(formula):
    if formula is None:
        return False
    if formula[0] == 'floor':
        return True
    return containsFloor(formula[2])

inverseOperation = {
    '+': '-',
    '-': '+',
    '*': '/',
    '/': '*',
    'floor': 'no-op',
    'no-op': 'no-op'
}
    
def invertHelper(formula, prev):
    if formula is None:
        return prev
    return invertHelper(formula[2], (inverseOperation[formula[0]], formula[1], prev))

def invert(formula):
    return invertHelper(formula, None)

# Returns a new formulaA with formulaB inside    
def chain(formulaA, formulaB):
    if formulaA is None:
        return formulaB
    return (formulaA[0], formulaA[1], chain(formulaA[2], formulaB))

def stripParens(str):
    if len(str) == 0:
        return str
    if str[0] == '(' and str[-1] == ')':
        return str[1:-1].strip()
    return str.strip()
    
def genEquationN(identifier, argIndex):
    def getEquationN(formula):
        if formula is None:
            return identifier
        op, arg, next = formula
        innerExpression = getEquationN(next)
        if op == 'floor':
            return ''.join(['Math.floor(', stripParens(innerExpression), ')'])
        if op == 'no-op':
            return innerExpression
        if type(arg) is types.TupleType:
            arg = arg[argIndex]
        return ' '.join(['(', innerExpression, op, arg, ')'])
    return getEquationN

getEquationX = genEquationN('x', 0)
getEquationY = genEquationN('y', 1)
    
def createConversionFunction(path, formula):
    return ''.join([
        '%s.' % className , '.'.join(path) , ' = (x, y) ->\n' ,
        '    return [\n' ,
        '        ' , stripParens(getEquationX(formula)) , ',\n' ,
        '        ' , stripParens(getEquationY(formula)) , '\n' ,
        '    ]\n'
    ])
    
# http://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm
# takes
#     a list of names (the nodes)
#     an edge cost function
# returns a tuple of that path cost dictionary and the next dictionary
def findShortestPaths(nodes, cost):
    pathCost = {}
    next = {}
    
    for a in nodes:
        for b in nodes:
            next[(a, b)] = None
            pathCost[(a, b)] = cost(a, b)
    
    for a in nodes:
        for b in nodes:
            for c in nodes:
                if pathCost[(b, a)] + pathCost[(a, c)] < pathCost[(b, c)]:
                    pathCost[(b, c)] = pathCost[(b, a)] + pathCost[(a, c)]
                    next[(b, c)] = a

    return (pathCost, next)
    
def genCostFunction(formulas):
    def cost(a, b):
        if a is b:
            return 0.0
        if (a, b) in formulas:
            formula = formulas[(a, b)]
            if containsFloor(formula):
                return 100.0
            else:
                return 1.0
        else:
            return float("inf")
    return cost

def getSpaces(formulas):
    spaces = set()
    for edge in formulas:
        spaces |= set(edge)
    return spaces
    
def generateInverses(formulas):
    return [(tuple(reversed(edge)), invert(formulas[edge])) for edge in formulas]

def genFormulaChainer(formulas, pathCost, next):
    memoized = {}
    def formulaChainer(src, dst):
        if (src, dst) in memoized:
            return memoized[(src, dst)]
        if pathCost[(src, dst)] == float("inf"):
            return None
        
        if (src, dst) in formulas:
            value = formulas[(src, dst)]
        else:
            intermediate = next[(src, dst)]
            value = chain(formulaChainer(intermediate, dst), formulaChainer(src, intermediate))
        memoized[(src, dst)] = value
        return value
    return formulaChainer
    
def generateAllFormulas(spaces, formulaChainer):
    formulas = {}
    for a in spaces:
        for b in spaces:
            if a is not b:
                formula = formulaChainer(a, b)
                if formula is not None:
                    formulas[(a, b)] = formula
    return formulas
    
def createCoffeescriptObject(space):
    return className + '.' + space + ' = {}'
    
def createCoffeescript(spaces, formulas):
    lines = []
    lines.append('declare "%s", %s = {}' % (className, className))
    lines.extend([createCoffeescriptObject(space) for space in spaces])
    lines.extend([createConversionFunction(path, formulas[path]) for path in formulas])
    return '\n'.join(lines)
    
def generateCoffeescript(formulas):
    spaces = getSpaces(formulas)
    formulas.update(generateInverses(formulas))
    
    pathCost, next = findShortestPaths(spaces, genCostFunction(formulas))
    formulaChainer = genFormulaChainer(formulas, pathCost, next)
    
    allFormulas = generateAllFormulas(spaces, formulaChainer)
    return createCoffeescript(spaces, allFormulas)

print generateCoffeescript({
    ("Game", "GameLevelTile"):
        ('floor', None,
            ('/', 'Level.TILE_SIZE', None)),
    ("WebGL", "Canvas"):
        ('floor', None,
            ('*', ('(Engine.canvas.width / 2)', '(-Engine.canvas.height / 2)'),
                ('+', ('1', '-1'), None))),
    ("Game", "WebGL"):
        ('/', ('(Engine.canvas.width / 2)', '(Engine.canvas.height / 2)'),
            ('-', ('Engine.camera.pos[0]', 'Engine.camera.pos[1]'), None)),
    ("TilesetOverview", "Tileset"):
        ('floor', None,
            ('/', ('(Level.TILE_SIZE + 1)'),
                ('-', ('1'), None))),
    ("TilePreview", "Tile"):
        ('*', ('(Level.TILE_SIZE / TilesetEditor.TILE_PREVIEW_SIZE)'),
           ('-', ('1'), None))
})
