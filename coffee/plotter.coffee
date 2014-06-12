# plotter classes for svgerber

# we need the aperture and board class
#require 'layer'
#require 'aperture'

# export the Plotter
root = exports ? this

class root.Plotter
  # constructor takes the filestring and the name of the layer
  constructor: (@gerber, @name) ->
    # gerber file reading variables
    # also set the current file index to 0
    @index = 0
    # keep a line counter for convenience
    @line = 1
    # file end flag
    @end = false

    # create a new layer
    @layer = new Layer @name

    # plotter parameters
    # set the format set flag to false and the rest to null
    @format = {
      set: false
      zero: null
      notation: null
      int: null
      dec: null
    }
    # set the units to null
    @units = null
    # tool list
    @tools = {}
    # polarity
    @polarity = 'D'

    # plotter operation
    @tool = null
    # plotter position
    @position = {
      x: 0
      y: 0
    }

    # plotter state
    # line / arc mode
    @mode = {
      int: null
      quad: null
    }
    # region mode
    @region = {
      state: off
      current: null
      startX: null
      startY: null
    }

  # plot the layer by reading the gerber file
  plot: ->
    # loop until the file ends
    until @end or @index >= @gerber.length
      # peak at the next character in the file
      next = @gerber[@index]
      # let's figure out what we're doing
      # if the next character is a %, then we're dealing with a parameter command
      if next is '%'
        @readParameter()
      # else, it's a normal, everyday data block
      else
        console.log "data block found at line #{@line}"
        block = @readBlock()
        console.log "block found: #{block}"

        while block.length > 0
          # check for an end of file
          if block.match /^M0?2$/
            console.log "end of file at line #{@line-1}"
            @end = true
            block = ''

          # check for a state command (G code)
          else if block.match /^G[01234579][0-7]?/
            console.log "state command at line #{@line-1}"
            block = @processState block

          # check for a operation code (D code)
          else if block.match /D[0-9]\d*$/
            console.log "operation command at line #{@line-1}"
            block = @operate block

          # check for a state command
          else
            console.log "don't know what to do with #{block} at line #{@line-1}"
            block = ''

    # set the layer units
    @layer.setUnits @units
    # return the layer
    @layer

  # process the plotter state given a line with a G code in it
  processState: (command) ->
    console.log "changing plotter state given #{command}"
    # get the g command
    g = command.match /^G[01234579][0-7]?/
    if g? then g = g[0] else throw "error: #{command} is not a valid state command"
    # act accordgingly
    switch g
      # linear interpolation mode
      when 'G1', 'G01'
        @mode.int = 1
        console.log "interpolation mode set to linear"
      # arc interpolation
      when 'G2', 'G02'
        @mode.int = 2
        console.log "interpolation mode set to clockwise arc"
      when 'G3', 'G03'
        @mode.int = 3
        console.log "interpolation mode set to counter clockwise arc"
      # comment mode
      when 'G4', 'G04'
        console.log "comment; ignoring"
        # set the command to empty
        command = ''
      # region mode on
      when 'G36'
        if @region.state is off
          @region.state = on
          @region.current = null
          @region.startX = null
          @region.startY = null
          console.log "region mode on"
      # region mode off
      when 'G37'
        if @region.state is on
          @region.state = off
          if @region.current? then @finishRegion()
          console.log "region mode off"
      # single quadrant mode
      when 'G74'
        @mode.quad = 74
        console.log "quadrant mode set to single"
      # multi quadrant mode
      when 'G75'
        @mode.quad = 75
        console.log "quadrant mode set to multiple"
      # deprecated commands
      when 'G54', 'G55', 'G70', 'G71', 'G90', 'G91'
        console.log "deprecated command #{g}; ignoring"
      # else unrecognized g code
      else
        throw "error at #{@line}: #{g} is unrecognized"
    # return the command with the G code stripped out
    if command.length > g.length
      command[g.length..]
    else
      ''

  # operate the plotter given a block with a D code in it
  operate: (command) ->
    console.log "operating the plotter given #{command}"
    # get the d code
    d = command.match /D[0-9]\d*$/
    if d? then d = d[0] else throw "error: #{command} is not a valid operation command"
    # act acordingly
    switch d
      when 'D1', 'D01'
        console.log 'interpolate operation found'
        @interpolate @getCoordinates(command)
      when 'D2', 'D02'
        console.log 'move operation found'
        @move @getCoordinates(command)
      when 'D3', 'D03'
        console.log 'flash operation found'
        @flash @getCoordinates(command)
      else
        console.log 'change tool command found'
        @changeTool d
    # return an empty string
    ''

  # get coordinates given a command block
  getCoordinates: (command) ->
    c = {}
    # x coordinate
    c.x = command.match /X[+-]?\d+/
    if c.x? then c.x = @parseCoordinate c.x[0][1..] else c.x = @position.x
    # y
    c.y = command.match /Y[+-]?\d+/
    if c.y? then c.y = @parseCoordinate c.y[0][1..] else c.y = @position.y
    # i
    c.i = command.match /I[+-]?\d+/
    if c.i? then c.i = @parseCoordinate c.i[0][1..]
    else if @mode.int isnt 1 then c.i = 0
    # j
    c.j = command.match /J[+-]?\d+/
    if c.j? then c.j = @parseCoordinate c.j[0][1..]
    else if @mode.int isnt 1 then c.j = 0

    # return c
    c

  # parse a number according to the format spec of the file
  parseCoordinate: (coord) ->
    # remove any signs and set a negative flag if necessary
    negative = false
    if coord[0] is '-'
      negative = true
      coord = coord[1..]
    if coord[0] is '+'
      coord = coord[1..]

    # if leading zero omission
    if @format.zero is 'L'
      coord = coord[0...-@format.dec] + '.' + coord[-@format.dec..]
    else if @format.zero is 'T'
      coord = coord[0...@format.int] + '.' + coord[@format.int..]

    # turn c into a number (negative if necessary)
    coord = parseFloat coord
    if negative then coord *= -1
    # return c
    coord

  # finish the current region
  finishRegion: ->
    console.log "closing region at line #{@line}"
    if @position.x is @region.startX and @position.y is @region.startY
      # end path
      @region.current.push 'Z'
      # create the region
      @layer.addFill @region.current
      # empty out the region
      @region.current = null
    else
      throw error "error at #{@line}: region close command on open contour"

  # interpolate to the given coordinates
  interpolate: (c) ->
    # check for a valid mode
    unless 1 <= @mode.int <= 3 then throw "error at #{line}: #{@mode.int} is not a valid mode for interpolation"

    # if we're in region mode, we're gonna be doing some region things
    if @region.state is on
      console.log "region mode is on; interpolating"
      # create a new region if it hasn't been created
      unless @region.current?
        console.log 'starting new region'
        @region.current = ['M', @position.x, @position.y]
        @region.startX = @position.x
        @region.startY = @position.y
      # line mode
      if @mode.int is 1
        console.log 'adding line to region'
        @region.current.push 'L', c.x, c.y
      # arc mode
      else if @mode.int is 2 or @mode.int is 3
        console.log 'adding arc to region'
        r = null
        xAxisRot = 0
        # large arc flag is true (1) if quad mode is multi (G75)
        largeArcFlag = @mode.quad - 74
        # sweep flag is true (1) if direction is CCW
        sweepFlag = 3 - @mode.int

        # find the radius by checking which offset signs work
        # in multi quadrant mode, signs are specified, so if it's a good arc
        # it will break the loop after the first iteration
        for n in [ [1,1], [1,-1], [-1,1], [-1,-1] ]
          # distance squared from the test center to the start
          rs2 = (@position.x - n[0] * c.i)**2 + (@position.y - n[1] * c.j)**2
          # same for the end
          re2 = (c.x - n[0] * c.i)**2 + (c.y - n[1] * c.j)**2
          # if they equal(ish), we've found the radius
          if rs2 - re2 < 0.00001
            r = Math.sqrt(rs2)
            break

          # push the path
          @region.current.push 'A', r, r, xAxisRot, largeArcFlag, sweepFlag, c.x, c.y

    # else we're just creating traces like a normal person
    else
      # straight trace
      if @mode.int is 1
        console.log "creating straight trace"
        @layer.addTrace @tool, @position.x, @position.y, c
      else if @mode.int is 2
        console.log "creating cw arc trace"
      else if @mode.int is 3
        console.log "creating ccw arc trace"

    # move the plotter to the new position
    @moveTo c

  # execute a move operation to the given coordinates
  move: (c) ->
    # if we're in region mode and a region is active, we need to get a little fancy
    if @region.state is on and @region.current?
      @finishRegion()
    # finally, move to the new coordinates
    @moveTo c

  # simply move the current position to the coordinates
  moveTo: (c) ->
    @position.x = c.x
    @position.y = c.y
    console.log "moved to #{c.x}, #{c.y}"

  # flash at the given coordinates
  flash: (c) ->
    # flash command should only happen if we're not in region mode
    if @region.state is on then throw "error at #{@line}: cannot flash (D03) in region mode"
    unless @tool? then throw "error at #{@line}: no tool selected for flash"
    @layer.addPad @tool, c.x, c.y
    # move the plotter position
    @moveTo c

  # read from the current index (inclusive) to the next end of block
  readBlock: ->
    block = ''
    while @gerber[@index] isnt '*'
      if @gerber[@index] is '\n' then @line++
      else
        block += @gerber[@index]
      @index++
    # skip past the end of block character and any new lines
    while @gerber[@index] is '*' or @gerber[@index] is '\n' or @gerber[@index] is '\r'
      if @gerber[@index] is '\n' then @line++
      @index++

    # return the block
    block

  # read a parameter command
  readParameter: ->
    # character checker
    c = ''
    # loop
    until c is '%'
      # get the data block
      block = @readBlock()
      # switch through the possible parameter commands
      param = block[1..2]
      command = block[3..]
      switch param
        when 'FS'
          console.log "format command at line #{@line}: #{block}"
          @setFormat command
        when 'MO'
          console.log "unit mode command at line #{@line}: #{block}"
          @setUnitMode command
        when 'AD'
          console.log "aperture definition at line #{@line}: #{block}"
          @createTool command
        when 'AM'
          console.log "aperture macro at line #{@line}: #{block}"
        when 'SR'
          console.log "step repeat command at line #{@line}: #{block}"
        when 'LP'
          console.log "level polarity at line #{@line}: #{block}"
          @setPolarity
      # get the check character
      c = @gerber[@index]

    # done with parameter block
    console.log "done with parameter block"
    # push past the trailing % and any newlines
    @index++
    while @gerber[@index] is '\n' or @gerber[@index] is '\r'
      if @gerber[@index] is '\n' then @line++
      @index++

  # set the format according to the passed command
  setFormat: (command) ->
    console.log "setting format according to #{command}"

    # throw an error if format has already been set
    if @format.set then throw "error at #{line}: format has already been set"

    # leading or trailing omission
    zero = command[0]
    if zero is 'L' or zero is 'T' then @format.zero = zero
    else throw "#{zero} at line #{@line} is invalid zero omission value (L or T)"

    # coordinate values
    notation = command[1]
    if notation is 'A' or notation is 'I' then @format.notation = notation
    else throw "#{notation} at line #{@line} is invalid notation value (A or I)"

    # coordinate format
    xFormat = command[2..4]
    yFormat = command[5..7]
    # throw errors if there's not an X and Y
    if xFormat[0] isnt 'X' then throw "error at #{line}: #{xFormat[0]} is not a valid coordinate"
    if yFormat[0] isnt 'Y' then throw "error at #{line}: #{yFormat[0]} is not a valid coordinate"
    # throw an error if the formats don't match
    if xFormat[1..] isnt yFormat[1..] then throw "error at #{line}: x format and y format don't match"
    # parse and throw appropriate errors
    @format.int = parseInt(xFormat[1], 10)
    @format.dec = parseInt(xFormat[2], 10)
    if @format.int > 7 then throw "error at #{line}: #{@format.int} exceeds max interger places of 7"
    if @format.dec > 7 then throw "error at #{line}: #{@format.dec} exceeds max decimal places of 7"

    # if we reach here without throwing any errors, format has been properly set
    console.log "zero omission set to: #{@format.zero}, coordinate notation set to: #{@format.notation}, integer places set to #{@format.int}, decimal places set to #{@format.dec}"
    @format.set = true

  # set the unit mode according to the passed command
  setUnitMode: (command) ->
    console.log "setting unit mode according to #{command}"

    # throw an error if mode has already been set
    if @units? then throw "error at #{@line}: unit mode has already been set"

    # set the units
    if command is 'IN'
      @units = 'in'
    else if command is 'MM'
      @units = 'mm'
    else
      throw "#error at #{@line}: #{command} is not a valid unit mode (IN or MM)"

    # if we get here without throwing an error, we're good
    console.log "unit mode set to: #{@units}"

  # set the level polarity according to the passed command
  setPolarity: (command) ->
    console.log "setting polarity according to #{command}"

    # if it's a good command, set the polarity and set the position to undefined
    if command is 'C' or command is 'D'
      @polarity = command
      @position.x = null
      @position.y = null
    else throw "error at #{@line}: #{command} is not a valid polarity (C or D)"

  # change tool to the code passed
  changeTool: (code) ->
    # tool change command should only happen if we're not in region mode
    if @region.state is on then throw "error at #{@line}: cannot change tool (Dnn) in region mode"
    # make sure tool cod exists
    unless @tools[code]? then throw "error at #{@line}: tool #{code} does not exist"
    # change the tool
    @tool = @tools[code]
    console.log "tool changed to #{code}"

  # create a new aperture and add it to the tools list
  createTool: (command) ->
    console.log "creating a aperture according to #{command}"

    toolCode = command[0..2]
    # throw an error if the tool number is bad
    # valid tool numbers: D10..
    unless toolCode.match /D[1-9]\d+/ then throw "error at #{@line}: #{toolCode} is not a valid tool number"
    # also throw an error if it already exists
    if @tools[toolCode]? then throw "error at #{@line}: #{toolCode} already exists"

    # get the shape
    toolShape = command[3..4]
    toolParams = command[5..]
    switch toolShape
      when 'C,'
        toolParams = @getCircleToolParams toolParams
      when 'R,'
        toolParams = @getRectToolParams toolParams
      when 'O,'
        toolParams = @getRectToolParams toolParams
      when 'P,'
        toolParams = @getPolyToolParams toolParams

      else
        console.lot "tool #{toolCode} might be a macro"

    # create the actual aperture and add it to the tools object
    tool = new Aperture(toolCode, toolShape[0], toolParams)
    @tools[toolCode] = tool
    # create aperture sets the current tool to the one just defined
    @changeTool toolCode

  # get the parameters for a circle aperture
  getCircleToolParams: (command) ->
    numbers = @gatherToolParams command
    # there must be between 1 and 3 numbers
    unless 1 <= numbers.length <= 3 then throw "error at #{line}: circle aperture must have between 1 and 3 params"

    # throw error if dia is not a whole number
    unless numbers[0] >= 0 then throw "error at #{line}: circle dia must be greater than or equal to 0"

    # create the params object with the diameter
    params = {
      dia: numbers[0]
    }
    # hole stuff if it exists
    if numbers[1]?
      unless numbers[1] >= 0 then throw "error at #{line}: hole x size must be greater than or equal to 0"
      params.holeX = numbers[1]
    if numbers[2]?
      unless numbers[2] >= 0 then throw "error at #{line}: hole y size must be greater than or equal to 0"
      params.holeY = numbers[2]

    # return the params object
    params

  # get the parameters for a rectangle or obround aperture
  getRectToolParams: (command) ->
    numbers = @gatherToolParams command
    # there must be between 2 and 4 numbers
    unless 2 <= numbers.length <= 4 then throw "error at #{line}: rect/obround aperture must have between 2 and 4 params"

    # throw an error if size params aren't greater than zero
    unless numbers[0] > 0 then throw "error at #{line}: rect/obround x size must be greater than 0"
    unless numbers[1] > 0 then throw "error at #{line}: rect/obround y size must be greater than 0"

    # create the params object with the diameter
    params = {
      sizeX: numbers[0]
      sizeY: numbers[1]
    }
    # hole stuff if it exists
    if numbers[2]?
      unless numbers[2] >= 0 then throw "error at #{line}: hole x size must be greater than or equal to 0"
      params.holeX = numbers[2]
    if numbers[3]?
      unless numbers[3] >= 0 then throw "error at #{line}: hole y size must be greater than or equal to 0"
      params.holeY = numbers[3]

    # return the params object
    params

  # get the parameters for a polygon aperture
  getPolyToolParams: (command) ->
    numbers = gatherToolParams command
    # there must be between 2 and 5 numbers
    unless 2 <= numbers.length <= 5 then throw "error at #{line}: polygon aperture must have between 2 and 4 params"

    # circumscribed circle dia must be greater than 0
    unless numbers[0] > 0 then throw "error at #{line}: polygon diameter must be greater than 0"
    # number of polygon points must be between 3 and 12
    unless 3 <= numbers[1] <= 12 then throw "error at #{line}: polygon must have 3 to 12 points"

    params = {
      dia: numbers[0]
      points: numbers[1]
    }

    # other stuff if it exists
    # rotation (negative or positive allowed)
    if numbers[2]? then params.rotation = numbers[2]
    if numbers[3]?
      unless numbers[3] >= 0 then throw "error at #{line}: hole x size must be greater than or equal to 0"
      params.holeY = numbers[3]
    if numbers[4]?
      unless numbers[4] >= 0 then throw "error at #{line}: hole y size must be greater than or equal to 0"
      params.holeY = numbers[4]

    # return the params object
    params

  # generic method to gather all the numbers in a basic aperture definition
  gatherToolParams: (command) ->
    # look for numbers in the proper format
    # ___X___X___
    numbers = command.match /[\+-]?[\d\.]+(?=X|$)/g
    # check that the numbers are actually numbers
    for n, i in numbers
      unless n.match /^[\+-]?((\d+\.?\d*)|(\d*\.?\d+))$/ then throw "error at #{line}: #{n} is not a valid number"
      numbers[i] = parseFloat n
    # return the array
    numbers
