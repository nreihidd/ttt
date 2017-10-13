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
        return "// js-include.py: Ignored duplicate include: %s" % path
    included[path] = True
    dir = getDirectory(path)
    return ''.join([
        "// js-include.py: Start %s\n" %path,
        processFile(dir, open(path, 'r')),
        "\n// js-include.py: End %s\n;\n" %path
    ])

def getFileProcessor(dir):
    persistent = {
        'inIncludeBlock': False,
        'inClosure': False 
    }
    def processLine(line):
        if line.startswith('//!include'):
            subpath = line.split(' ', 1)[1].strip()
            path = os.path.normpath(os.path.join(dir, subpath))
            return includeFile(path)
        elif line.startswith('/* INCLUDE'):
            persistent['inIncludeBlock'] = True
            return ''
        elif persistent['inIncludeBlock']:
            if line.startswith('*/'):
                persistent['inIncludeBlock'] = False
                return ''
            elif line.strip() == 'CLOSURE':
                persistent['inClosure'] = True
                return '(function() { \n'
            else:
                return includeFile(os.path.normpath(os.path.join(dir, line.rstrip())))
        #return mangleClasses(line)
        return line
    def endFile():
        if persistent['inClosure']:
            return '})();\n'
        else:
            return ''
    return processLine, endFile

def processFile(dir, file):
    lines = file.readlines()
    processor, endFile = getFileProcessor(dir)
    slist = [processor(l) for l in lines]
    return ''.join(slist) + endFile() +'\n'
    
if __name__ == '__main__':
    if len(sys.argv) != 2:
        print "Usage: ./js-include.py input-file.js\n"
        exit(1)
    path = sys.argv[1]
    dir = getDirectory(path)
    
    input = open(path, 'r')
    
    sys.stdout.write(processFile(dir, input))