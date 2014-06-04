# plotter class for svgerber
# constructor takes in gerber file as string

# export the class for node or browser
root = exports ? this

# aperture class
class Aperture
  constructor: (@code, @shape, @params) ->
    console.log "Aperture " + @code + " was created and is a " + @shape

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
    # notify those concerned
    console.log "Plotter created"

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
      console.log "zero omission set to: " + @zeroOmit
    else
      throw "NoZeroSuppressionInFormatSpecError"

    # check for and parse coordinate notation
    @notation = fS.match notationMatch
    if @notation?
      @notation = @notation[0][0]
      console.log "notation set to: " + @notation
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
    else
      console.log "coordinate format set to: " + @leadDigits + ", " + @trailDigits

  parseUnits: (u) ->
    unitMatch = /^%MO((MM)|(IN))\*%/
    if u.match unitMatch
      @units = u[3..4]
    else
      throw "NoValidUnitsGivenError"

  parseAperture: (a) ->
    # specific aperture parsing functions
    # circle parsing
    parseCircle = (shape) ->
      circleMatch = ///
        C,[\d\.]+         # circle with diameter definition
        (X[\d\.]+){0,2}   # up to two optional parameters for hole
        $                 # end of string
      ///
      # if it's a good circle input
      if shape.match circleMatch
        # get the numbers
        params = shape.match /[\d\.]+/g
        for p, i in params
          # check for a valid decimal number
          if p.match /^((\d+\.?\d*)|(\d*\.?\d+))$/
            params[i] = parseFloat p
          else
            throw "BadCircleApertureError"
        params
      # else throw an error
      else
        throw "BadCircleApertureError"

    # rectangle parsing
    parseRectangle = (shape) ->
      rectangleMatch = ///
        R,[\d\.]+X[\d\.]+ # rectangle with x and y definition
        (X[\d\.]+){0,2}   # up to two optional parameters for hole
        $                 # end of string
      ///
      # if it's a good circle input
      if shape.match rectangleMatch
        # get the numbers
        params = shape.match /[\d\.]+/g
        for p, i in params
          # check for a valid decimal number
          if p.match /^((\d+\.?\d*)|(\d*\.?\d+))$/
            params[i] = parseFloat p
          else
            throw "BadRectangleApertureError"
        params
      # else throw an error
      else
        throw "BadRectangleApertureError"


    # first, check that input was at least a little good
    apertureMatch = /^%AD.*$/
    if not a.match apertureMatch
      throw "InputTo_parseAperture_NotAnApertureError"

    # get tool code
    code = a.match /D[1-9]\d+/
    if code?
      code = parseInt(code[0][1..], 10)
    else
      throw "InvalidApertureToolCodeError"

    # get shape and parse accordingly
    shape = a.match /[CROP].*(?=\*%$)/
    if shape?
      shape = shape[0]
      params = (
        switch shape[0]
          when "C"
            parseCircle shape
          when "R"
            parseRectangle shape
          when "O", "P"
            throw "UnimplementedApertureError"

      )
      shape = shape[0]
    else
      throw "NoApertureShapeError"

    # return the aperture
    a = new Aperture(code, shape, params)

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
          @parseFormatSpec line
          gotFormat = true
        else if line.match unitMatch
          @parseUnits line
          gotUnits = true
      # once we've got those things, we can read the rest of the file
      else
        # check for an aperture definition
        if line.match apertureMatch
          ap = @parseAperture line
          if @apertures[ap.code-10] is null
            @apertures[ap.code]
          else
            throw "ApertureAlreadyExistsError"

    # once we leave the read loop
    # problem if we never saw a format
    if not gotFormat
      throw "NoFormatSpecGivenError"
    if not gotUnits
      throw "NoValidUnitsGivenError"
