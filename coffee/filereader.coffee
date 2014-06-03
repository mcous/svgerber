# simple file reader for svGerber

# check for file api support
# looks good to me
# if window.File and window.FileReader and window.FileList and window.Blob
#   alert 'file api is go'
# else
#   alert 'file api is no'

# assume the coordinate format is:
#   decimal
#   x5.5, y5.5
coordFormat =
  zeros:  'D'
  xLead:  5
  xTrail: 5
  yLead:  5
  yTrail: 5

# assume units are in mm
units = 'M'

# apertures
aps = []

# aperture class
class Aperture
  constructor: (@code, @shape) ->
    console.log @print()

  print: ->
    "aperture " + @code + " is a " + (
      if @shape is 'C'
        "circle"
      else if @shape is 'R'
        "rectangle"
      else if @shape is 'O'
        "obcircle"
      else if @shape is 'P'
        "polygon"
    )


# find a line with a regex pattern
findLine = (lines, pattern) ->
  # find the format declaration
  line = 0
  line++ while line < lines.length and not lines[line].match pattern
  line

# create an aperture from the gerber command
createAperture = (lineText) ->
  # get the tool code and shape
  code = lineText.match(/D\d{2,}/)[0][1..]
  shape = lineText.match(/[CROP]/)[0]
  aps[code] = new Aperture(code, shape)

# gather all the necessary apertures
getGerberApertures = (lines) ->
  # aperture definition match
  apertureMatch = ///
    ^%AD    # start of string and aperture definition command
    D\d{2,} # aperture code (e.g. D11)
    (
      (
        C,\d*\.\d+         # circle with diameter definition
        (X\d*\.\d+){0,2}   # up to two optional parameters for hole
      ) | (
        [RO],\d*\.\d+      # rectangle or obround with x definition
        (X\d*\.\d+){1,3}   # 1 to 3 additional params for y and hole
      ) | (
        P,\d*\.\d+         # polygon with diameter of circumscribed circle
        X([3-9]|1[0-2])    # number of points (3 to 12)
        (
          X-?\d*\.\d+      # rotation in decimal (can be negative)
          (X\d*\.\d+){0,2} # up to two optional parameters for hole
        )?
      )
    )
    \*%$   # end of command and string
  ///

  # gather the aperture definition lines
  foundLines = []
  line = 0
  while line < lines.length
    line = findLine(lines, apertureMatch)
    if line < lines.length
      createAperture lines[line]
      lines = lines[(line+1)..]

  # return the stripped lines array
  lines

# get the gerber units
getGerberUnits = (lines) ->
  # looking for %MOIN*% or %MOMM*%
  unitMatch = /^%MO((IN)|(MM))\*%/
  line = findLine(lines, unitMatch)

  # if the line was found
  if line < lines.length
    currentLine = lines[line]

    # set units to I or M
    units = currentLine[3]
    console.log "units are " + (if units is 'I' then "inches" else "mm")

    # return the array with other stuff spliced out
    lines[(line+1)..]

  # else no units were given (fatal)
  else
    console.log "no units specified"
    []

# get the gerber format
getGerberFormat = (lines) ->
  formatMatch = /// ^  # start of regex and line
    %FS                # looking for file specification
    [LTD]              # then, an Leading Zeros Omitted, Trailing, or Decimal
    [AI]               # Absolute or Incremental
    (N\d+)?            # optional sequence number
    (G\d+)?            # optional preparatory function code
    X[0-5]{2}          # x data format
    Y[0-5]{2}          # y data format
    (D\d+)?            # optional draft code
    (M\d+)?            # optional misc code
    \*%$               # end of file spec and line
  ///                  # end of regex

  # find the format declaration
  line = findLine(lines, formatMatch)

  # if it was found
  if line < lines.length
    currentLine = lines[line]

    # get zero format
    coordFormat.zeros = currentLine.match(/[L,T,D]/)[0]
    # get x format
    [coordFormat.xLead, coordFormat.xTrail] = currentLine.match(/X[0-5]{2}/)[0][1..2]
    # get y format
    [coordFormat.yLead, coordFormat.yTrail] = currentLine.match(/Y[0-5]{2}/)[0][1..2]

    console.log "zero format: " + coordFormat.zeros
    console.log "x format: " + coordFormat.xLead + ", " + coordFormat.xTrail
    console.log "y format: " + coordFormat.yLead + ", " + coordFormat.yTrail

    # return the array with stuff that's been read spliced out
    lines[(line+1)..]

  # else no format data given (fatal)
  else
    # return an empty array
    console.log "no format information found"
    []



# convert a file to an svg
fileToSVG = (file) ->
  lines = file.split "\n"
  lines = getGerberFormat lines
  lines = getGerberUnits lines

  lines = getGerberApertures lines

  console.log lines
  console.log aps

# read a file to a div
readFileToDiv = (event) ->
  if event.target.readyState is FileReader.DONE
    textDiv = document.createElement 'p'
    textDiv.innerHTML = fileToSVG event.target.result
    document.getElementById('file-contents').insertBefore(textDiv, null)

# take care of a file event
handleFileSelect = (event) ->
  # arrays for the uploaded files
  importFiles = event.target.files
  output = []

  # add some html to the output
  for f in importFiles
    output.push '<li><strong>', escape(f.name), '</li>'

  # append the file names to the HTML
  document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>'

  # read the uploaded files to a div
  for f in importFiles
    # file reader with onload event attached
    reader = new FileReader()
    reader.addEventListener('loadend', readFileToDiv, false)
    reader.readAsText(f)

# attach the event listener
document.getElementById('files').addEventListener('change', handleFileSelect, false)
