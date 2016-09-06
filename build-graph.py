#!/usr/bin/env python

########################################################################

helpString = '''

This script creates partial UI's for visualizing compilation progress
in elm.  You should really use the makefile instead of invoking this
script directly.  However for completeness, here is the documentation.

Point this script at the toplevel of your elm project.  You must have
`dot` and `tred` installed and be a `git` user.  It is invoked as
follows (just FYI, because you should actually use the included
makefile to invoke it correctly):

$ python build-graph.py /path/to/your/project/toplevel

The output will be saved as .ReducedDigraph.elm in the current
directory.  Note that it is hidden because it is a temporary file.
Then run elm-make on a concatenation of CompilerPreamble.elm and
.ReducedDigraph.elm.  See the makefile for a target that does this
correctly.

'''

########################################################################

from subprocess import Popen, PIPE
import sys
import os
import re
import pprint
import xml.etree.ElementTree as ET


if len(sys.argv) < 2:
    print "\nERROR: There must be an argument which is a project directory."
    print helpString
    sys.exit(1)    
(projectDirectory) = sys.argv[1]
if not os.path.isdir(projectDirectory):
    print "\nERROR: The first argument is not a directory."
    print helpString
    sys.exit(1)    
if not os.path.isdir(os.path.join(projectDirectory, '.git')):
    print "\nERROR: The first argument is not a GIT directory."
    print helpString    
    sys.exit(1)

workingDirectory = os.getcwd()
os.chdir(projectDirectory)

# Obtain a list of elm files in the project from git.
p = Popen(["git", "ls-files"], stdout=PIPE, stderr=PIPE)
(stdOut, stdErr) = p.communicate()

projectFiles = [ fileName for fileName in stdOut.split('\n') if fileName.endswith('.elm') ]

# Read through the project filenames and figure out the dependencies
# based on the imports.
importRx = re.compile(r"^import[ \t]+(?P<importName>[^ \t\r\n]+)")
moduleRx = re.compile(r"^(port[ \t]+)?module[ \t]+(?P<moduleName>[^ \t\r\n]+)")
dependencies = {}

def createDependency(moduleName, importName):
    # print 'UNSORTED:', moduleName, 'depends on', importName
    dependencies[moduleName].append(importName)

def removeBlockComments(fileText):
    pieces = re.split(
        r'([{][-](?:[^-]|[-][-]*[^-}])*[-][-]*[}])', fileText, flags=re.DOTALL)
    newpieces = []
    for piece in pieces:
        if piece == None or piece == '':
            continue
        if piece[0:2] == '{-' and piece[-2:] == '-}':
            newpieces.append('\n' * (piece.count('\n')))        
        else:
            newpieces.append(piece)
    return ''.join(newpieces)

def removeLineComments(fileText):
    pieces = re.split(r'([-][-].*[\n])', fileText)
    newpieces = []
    for piece in pieces:
        if piece == None or piece == '':
            continue
        if piece[0:2] == '--' and piece[-1:] == '\n':
            newpieces.append('\n')
        else:
            newpieces.append(piece)
    return ''.join(newpieces)    
    
for filename in projectFiles:
    moduleName = ''
    moduleFound = False
    fi = open(filename, 'r')
    lines = fi.readlines()
    fi.close()
    fileText = ''.join(lines)
    fileText = removeBlockComments(fileText)
    fileText = removeLineComments(fileText)
    lineNumber = 0
    # The following adds and extra newline, but it doesn't matter.
    for line in [ x+'\n' for x in fileText.split('\n') ]:
        lineNumber = lineNumber + 1
        mo = moduleRx.match(line)
        if mo and not moduleFound:
            moduleName = mo.group('moduleName')
            dependencies.setdefault(moduleName, [])
            moduleFound = True
        else:
            mo = importRx.match(line)
            if mo and moduleFound:
                importName = mo.group('importName')
                createDependency(moduleName, importName)
            elif mo: # and not moduleFound
                moduleName = filename[:-4]
                dependencies.setdefault(moduleName, [])
                moduleFound = True
            else:
                # uninteresting line.
                pass


# We are only interested in files and modules from the project, not
# the imported ones from external libraries.  So we filter those out.
filteredDependencies = {}    
moduleList = dependencies.keys()

for targetModule, dependencyList in dependencies.items():
    filteredDependencyList = [
        x for x in dependencyList if x in moduleList ]
    excludedDependencyList = [
        x for x in dependencyList if not (x in moduleList) ]
    for ex in excludedDependencyList:
        # print 'EXCLUDED: ', targetModule, 'depends on', ex
        pass 
    filteredDependencies[targetModule] = filteredDependencyList

os.chdir(workingDirectory)

# Run dot as an external process to create a well-laid out SVG file of
# the dependencies.  Ie. not reinventing the wheel.
firstFileName = '.digraph.dot'
f = open(firstFileName, 'w')    
f.write('''
digraph MyProject {
    rankdir = LR;
/*
    splines = line;
    splines = true;
    splines = ortho;
    splines = polyline;
    splines = false;
*/
    splines = true;
''')
for targetModule, dependencyList in filteredDependencies.items():
    for dependency in dependencyList:
        # print 'INCLUDED: ', targetModule, 'depends on', dependency
        f.write('    "' + dependency + '" -> "' + targetModule + '"\n')
f.write('}\n')
f.close()

p = Popen(["tred", firstFileName], stdout=PIPE, stderr=PIPE)
(stdOut, stdErr) = p.communicate()
if stdErr.strip() != '':
    print stdErr
    sys.exit(1)
else:
    secondFileName = '.reduced-digraph.dot'
    f = open(secondFileName, 'w')
    f.write(stdOut)
    f.close()

finalFileName = '.reduced-digraph.svg'
p = Popen(["dot", "-Tsvg", secondFileName, "-o", finalFileName],
          stdout=PIPE, stderr=PIPE)
(stdOut, stdErr) = p.communicate()
if stdErr.strip() != '':
    print stdErr
    sys.exit(1)

tree = ET.parse(finalFileName)
root = tree.getroot()

# Small corrections that are needed to translate from standard SVG and
# to elm's svg library.
def disambiguate(k):
    if k in ['title', 'path', 'svg']:
        return 'Svg.' + k
    elif k in ['text']:
        return 'Svg.' + k + "'"
    elif k in []:
        return 'Svg.Attributes.' + k
    else:
        return k

# This function converts hyphenated variables to camelCase, for
# example 'text-anchor' to 'textAnchor'.
def dehyphenate(k):
    if k.find('-') != -1:
        p = k.find('-')
        return k[:p] + k[p+1:p+2].upper() + k[p+2:]
    else:
        return k

# We only change colors for ellipses -- here we insert code for
# reading the current compilation state of a fileName and translating
# that into a color within the view.
def insertColors(svgNodeType, nodeName, attribKey, attribValue):
    if svgNodeType != 'ellipse' or attribKey != 'fill':
        return '"' + attribValue + '"'
    else:
        return '(getColorCode model "' + nodeName + '")'
        
    
nodeName = ''
minIndent = '  ' # minimum indent.
leader = '{http://www.w3.org/2000/svg}'

# Does the recursive conversion of the xml svg tree to equivalent elm code.
def printSvg(f, node, indent):
    global nodeName
    if node.tag.startswith(leader):
        svgNodeType = node.tag[len(leader):]
    else:
        print "TAGWARNING: " + node.tag
        sys.exit(1)
        svgNodeType = node.tag
    f.write(disambiguate(svgNodeType) + '\n')

    # print attributes
    if len(node.attrib) == 0:
        f.write(minIndent * (indent+1) + '[]\n')
    else:
        firstTime = True
        for attribKey, attribValue in node.attrib.items():
            if firstTime:
                f.write(minIndent * (indent+1) + '[ ')
                firstTime = False
            else:
                f.write(minIndent * (indent+1) + ', ')
            f.write(dehyphenate(attribKey) + ' ' + insertColors(svgNodeType, nodeName, attribKey, attribValue) + '\n')
        f.write(minIndent * (indent+1) + ']\n')

    # print children or text
    if node.text != None and node.text.strip() != '':
        nodeName = node.text
        f.write(minIndent * (indent+1) + '[ Svg.text "' + node.text + '" ]\n')
    elif len(node) == 0:
        f.write(minIndent * (indent+1) + '[]\n')
    else:
        firstTime = True
        for child in node:
            if firstTime:
                f.write(minIndent * (indent+1) + '[ ')
                firstTime = False
            else:
                f.write(minIndent * (indent+1) + ', ')
            printSvg(f, child, indent+2)
        f.write(minIndent * (indent+1) + ']\n')

# Printing out the standard boilerplate header which consists of elm
# infrastructure code for this particular problem.
f = open('.ReducedDigraph.elm', 'w')
f.write('''

fileDependencies: Dict String (List String)
fileDependencies =
  Dict.fromList
''')

firstTime = True
for fileName in moduleList:
    if firstTime:
        f.write('    [ ("')
        firstTime = False
    else:
        f.write('    , ("')
    f.write(fileName + '", [' +
            ', '.join(
                [ '"'+x+'"' for x in filteredDependencies[fileName]]) +
            '])\n')
f.write('    ]')

# Now do the SVG translation from dot output to elm code.
f.write('''

view: Model -> Html Msg
view model =
 ''',)

printSvg(f, root, 1)
f.close()
