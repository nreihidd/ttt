import os, sys

included = {}

def getDirectory(path):
    dir, name = os.path.split(path)
    if len(dir) == 0:
        return '.'
    else:
        return dir

def includeFile(path):
    if path in included:
        return "# coffee-include.py: Ignored duplicate include: %s" % path
    included[path] = True
    dir = getDirectory(path)
    return ''.join([
        "# coffee-include.py: Start %s\n" %path,
        processFile(dir, open(path, 'r')),
        "\n# coffee-include.py.py: End %s\n" %path
    ])

def getFileProcessor(dir):
    persistent = {
        'inIncludeBlock': False
    }
    def processLine(line):
        if line.startswith('### IMPORT'):
            persistent['inIncludeBlock'] = True
            return ''
        elif persistent['inIncludeBlock']:
            if line.startswith('###'):
                persistent['inIncludeBlock'] = False
                return ''
            return includeFile(os.path.normpath(os.path.join(dir, line.rstrip())) + '.coffee')
        return line
    return processLine

def processFile(dir, file):
    lines = file.readlines()
    processor = getFileProcessor(dir)
    slist = [processor(l) for l in lines]
    return ''.join(slist) + '\n'
    
if __name__ == '__main__':
    if len(sys.argv) != 2:
        print "Usage: ./coffee-include.py input-file.coffee\n"
        exit(1)
    path = sys.argv[1]
    dir = getDirectory(path)
    
    input = open(path, 'r')
    
    sys.stdout.write(processFile(dir, input))