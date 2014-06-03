# plotter class for svgerber
# constructor takes in gerber file as string

# export the class for node or browser
root = exports #? this

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

class root.Plotter
  constructor: (gerberFile) ->
    # stuff we'll be using
    # formatting
    @zeroOmit = null
    @notation = null
    @leadDigits = null
    @trailDigits = null
    # units
    @units = null
    # aperture list
    @apertures = []


    # parse the monolithic string into an array of lines
    @gerber = gerberFile.split '\n'
    # strip out the comments
    # @gerber = []
    # for line in gerberFile
    #   @gerber.push(line) unless line.match(/^G04/)
    # notify those concerned
    console.log "Plotter class created"

  parseFormatSpec: (fS) ->
    formatMatch = /^%FS.*\*%$/  # file spec regex
    zeroMatch = /[LT]/          # leading or trailing zeros omitted
    notationMatch = /[AI]/      # Absolute or incremental notation
    xDataMatch = /X+?\d{2}/  # x data format
    yDataMatch = /Y+?\d{2}/  # y data format

    # throw an error if whatever comes in isn't a format spec
    if not fS.match formatMatch
      throw "InputTo_parseFormatSpec_NotAFormatSpecError"

    # check for and parse zero omission
    @zeroOmit = fS.match zeroMatch
    if @zeroOmit?
      @zeroOmit = @zeroOmit[0][0]
    else
      throw "NoZeroSuppressionInFormatSpecError"

    # check for and parse coordinate notation
    @notation = fS.match notationMatch
    if @notation?
      @notation = @notation[0][0]
    else
      throw "NoCoordinateNotationInFormatSpecError"

    # check for and parse coordinate format
    xFormat = fS.match xDataMatch
    yFormat = fS.match yDataMatch
    # check for existence
    if xFormat?
      xFormat = xFormat[0][-2..]
    else
      throw "MissingCoordinateFormatInFormatSpecError"
    if yFormat?
      yFormat = yFormat[0][-2..]
    else
      throw "MissingCoordinateFormatInFormatSpecError"
    # check for match
    if xFormat is yFormat
      @leadDigits = parseInt(xFormat[0], 10)
      @trailDigits = parseInt(xFormat[1], 10)
    else
      throw "CoordinateFormatMismatchInFormatSpecError"

    # check to make sure values are in range
    if not ((0 < @leadDigits < 8) and (0 < @trailDigits < 8))
      throw "InvalidCoordinateFormatInFormatSpecError"

  parseUnits: (u) ->
    unitMatch = /^%MO((MM)|(IN))\*%/
    if u.match unitMatch
      @units = u[3..4]
    else
      throw "NoValidUnitsGivenError"

  parseAperture: (a) ->
    a = new Aperture(10, "C")

  plot: ->
    # flags for specs
    gotFormat = false
    gotUnits = false
    fileEnd = false

    # operating modes
    interpolationMode = null
    quadrantMode = null

    # different types of lines (all others ignored)
    formatMatch   = /^%FS.*\*%$/           # file spec
    unitMatch     = /^%MO((MM)|(IN))\*%$/  # unit spec
    apertureMatch = /^%AD.*$/              # aperture definition

    # loop through the lines of the gerber
    for line in @gerber
      # first we need a format and units
      if (not gotFormat) or (not gotUnits)
        if line.match formatMatch
          parseFormatSpec line
          gotFormat = true
        else if line.match unitMatch
          parseUnits line
          gotUnits = true
      # once we've got those things, we can read the rest of the file
      else
        # check for an aperture definition

    # once we leave the read loop
    # problem if we never saw a format
    if not gotFormat
      throw "NoFormatSpecGivenError"
    if not gotUnits
      throw "NoValidUnitsGivenError"
