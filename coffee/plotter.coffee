# plotter classes for svgerber

# we need the aperture and board class
#require 'layer'
#require 'aperture'

# export the Plotter
root = exports ? this

# plotter class is exported
class root.Plotter
  # constructor takes in gerber file as string
  constructor: (gerberFile, @name) ->
    # stuff we'll be using
    # formatting
    @zeroOmit = null
    @notation = null
    @leadDigits = null
    @trailDigits = null
    # units
    @units = null
    # aperture list and current tool
    @apertures = []
    @tool = null
    # interpolation and arc mode
    @iMode = null
    @aMode = null
    # current position
    @xPos = 0
    @yPos = 0

    # parse the monolithic string into an array of lines
    @gerber = gerberFile.split '\n'
    # notify those concerned
    console.log "Plotter for #{@name} created"

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
          when "C", "R", "O"
            @parseBasicAperture shape
          when "P"
            throw "UnimplementedApertureError"

      )
      shape = shape[0]
    else
      throw "NoApertureShapeError"

    # return the aperture
    a = new Aperture(code, shape, params)

  # basic (circle, rectangle, obround) aperture parsing
  parseBasicAperture: (string) ->
    circleMatch = /// ^
      C,[\d\.]+         # circle with diameter definition
      (X[\d\.]+){0,2}   # up to two optional parameters for hole
      $                 # end of the string
    ///

    rectangleMatch = /// ^
      R,[\d\.]+X[\d\.]+ # rectangle with x and y definition
      (X[\d\.]+){0,2}   # up to two optional parameters for hole
      $                 # end of string
    ///

    obroundMatch = /// ^
      O,[\d\.]+X[\d\.]+ # obround with x and y definition
      (X[\d\.]+){0,2}   # up to two optional parameters for hole
      $                 # end of string
    ///

    badInput = true
    if (
      # figure out what shape tha aperture is and check format
      ((circle = (string[0][0] is 'C')) and string.match circleMatch) or
      ((rect = (string[0][0] is 'R')) and string.match rectangleMatch) or
      ((obround = (string[0][0] is 'O')) and string.match obroundMatch)
    )
      # if it passes that test, parse the floats
      params = string.match /[\d\.]+/g
      for p, i in params
        # check for a valid decimal number with
        if p.match /^((\d+\.?\d*)|(\d*\.?\d+))$/
          params[i] = parseFloat p
          badInput = false
        else
          badInput = true
          break

    # else throw an error
    if badInput
      if circle
        throw "BadCircleApertureError"
      else if rect
        throw "BadRectangleApertureError"
      else if obround
        throw "BadObroundApertureError"
    # return the parameters
    params

  parseGCode: (s) ->
    # throw an error if the input isn't a G-code
    match = (s.match /^G\d{1,2}(?=\D)/)
    if not match
      throw "InputTo_parseGCode_NotAGCodeError"
    else match = match[0]

    # get the actual code
    code = parseInt(match[1..], 10)
    # act accordingly
    switch code
      # codes 1, 2, and 3 are interpolation modes
      when 1, 2, 3
        @iMode = code
      # code 4 is a comment
      when 4
        console.log "found a comment"
        return ""
      # 74 and 75 determine the arc mode
      when 74, 75
        @aMode = code
      # 54 and 55 are deprecated and don't do anything
      when 54, 55
        console.log "deprecated G#{code} found"
      # 70 is a deprecated command to set the units to inches
      when 70
        if not @units?
          console.log "warning: deprecated G70 command used to set units to in"
          @units = 'IN'
      # 71 is a deprecated command to set the units to mm
      when 71
        if not @units?
          console.log "warning: deprecated G71 command used to set units to mm"
          @units = 'MM'
      # 90 is a deprecated command to set absolute notation
      when 90
        if not @notation?
          console.log "warning: deprecated G90 command used to set notation to abs"
          @notation = 'A'
      # 91 is a deprecated command to set incremental notation
      when 91
        if not @notation?
          console.log "warning: deprecated G91 command used to set notation to inc"
          @notation = 'I'
      else
        throw "G#{code}IsUnimplementedGCodeError"

    # return the rest of the string
    s[match.length..]

  # takes a coordinate in the form of [XY]nnnnnnn
  # returns a dec
  parseCoordinate: (coord) ->
    console.log "parsing coordinates"
    coord = coord[1..]
    if @zeroOmit is 'L'
      console.log "coord is #{coord}"
      c = coord[0..-(@trailDigits+1)] + '.' + coord[-@trailDigits..]
      console.log "c is #{c}"
      parseFloat c
    else if @zeroOmit is 'T'
      c = coord[0..@leadDigits] + '.' + coord[@leadDigits..]
      parseFloat coord[0..@leadDigits] + '.' + coord[@leadDigits..]

  parseMove: (line, layer) ->
    # get the x coordinate if there is one
    x = line.match /X[+-]?[\d]+/
    if x? then x = @parseCoordinate x[0]
    # do the same with y
    y = line.match /Y[+-]?[\d]+/
    if y? then y = @parseCoordinate y[0]

    command = line.match /D0?[123](?=\*$)/
    if command? then command = command[0][-1..]

    @move x, y, command, layer

  move: (x, y, command, layer) ->
    console.log command
    # if stroke command
    if command is '1'
      console.log "making line with aperture #{@tool.code}"
      layer.addObject('T', @tool, [@xPos, @yPos, x, y])
    else if command is '2'
      console.log "moving"
    else if command is '3'
      console.log "making pad"
      layer.addObject('P', @tool, [x, y])
    else
      throw 'BadOperationCodeError'
    console.log "moving to #{x}, #{y}"
    @xPos = x
    @yPos = y

  stroke: (x, y) ->
    t = new Trace(@tool, @xPos, @yPos, [x, y])

  flash: (x, y) ->
    console.log

  parseToolChange: (line) ->
    unless line.match /^D[1-9]\d+\*$/ then throw "BadToolLineError"
    tool = parseInt(line[1..-2], 10)
    @changeTool tool

  changeTool: (tool) ->
    if tool < 10 then throw "Tool_#{tool}_IsOutOfRangeError"
    @tool = @apertures[tool-10]

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
    apertureMatch = /^%AD.*\*%$/           # aperture definition
    gMatch        = /^G.*\*$/              # G command code
    endMatch      = /^M0?2\*$/             # end of file command code
    toolMatch     = /^D[1-9]\d+\*$/            # tool select command
    moveMatch     = /^(X[+-]?\d+)?(Y[+-]?\d+)?D0?[123]\*$/ # move command

    # create a new layer object
    layer = new Layer(@name)

    # loop through the lines of the gerber
    for line, i in @gerber
      # make sure the file hasn't ended
      if line.match endMatch
        console.log "#{line} indicates end of file at line: #{i}"
        fileEnd = true
        break

      # if we haven't got format and units yet, we'll need them
      if (not gotFormat) or (not gotUnits)
        if line.match formatMatch
          @parseFormatSpec line
          gotFormat = true
        else if line.match unitMatch
          @parseUnits line
          gotUnits = true
          layer.setUnits(@units)

      # once we've got those things, we can read the rest of the file
      else
        # take care of any commands
        if line.match gMatch
          line = @parseGCode line

        # line will now be stripped of any g commands
        # check for an aperture definition
        if line.match apertureMatch
          ap = @parseAperture line
          if not @apertures[ap.code-10]?
            @apertures[ap.code-10] = ap
          else
            throw "ApertureAlreadyExistsError"
        # check for a tool select command
        else if line.match toolMatch
          console.log "changing tool to #{line}"
          @parseToolChange line
          console.log "current tool #{@tool.code} is a #{@tool.shape}"
        # check for a move command
        else if line.match moveMatch
          # console.log "moving according to #{line}"
          @parseMove line, layer


        else
          console.log "don't know what #{line} means"

    # once we leave the read loop
    # problem if we never saw a format
    if not gotFormat
      throw "NoFormatSpecGivenError"
    if not gotUnits
      throw "NoValidUnitsGivenError"
    if not fileEnd
      throw "NoM02CommandBeforeEndError"

    # return the layer that was plotted
    layer
