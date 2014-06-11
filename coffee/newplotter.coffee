# plotter classes for svgerber

# we need the aperture and board class
#require 'layer'
#require 'aperture'

# export the Plotter
root = exports ? this

class root.Plotter
  # constructor takes the filestring and the name of the layer
  constructor: (@gerber, @name) ->
    # also set the current file index to 0
    @index = 0
    # keep a line counter for convenience
    @line = 0
    # file end flag
    @end = false
    # set the format set flag to false
    @format = {
      set: false
    }
    # set the mode flag to false
    @mode = {
      set: false
    }
    # create an empty tools object
    @tools = {}

  # plot the layer by reading the gerber file
  plot: ->
    # create a new layer
    layer = new Layer @name

    # loop until the file ends
    until @end is 10
      # peak at the next character in the file
      next = @gerber[@index]
      # let's figure out what we're doing
      # if the next character is a %, then we're dealing with a parameter command
      if next is '%'
        console.log "parameter command found at line #{@line}"
        @readParameter()
      # else, it's a normal, everyday data block
      else
        console.log "data block found at line #{@line}"
        block = @readBlock()
        console.log "block found: #{block}"

      # debugging
      @end++

    # return the layer
    layer

  # read from the current index (inclusive) to the next end of block
  readBlock: ->
    block = ''
    while @gerber[@index] isnt '*'
      if @gerber[@index] is '\n' then @line++
      else
        block += @gerber[@index]
      @index++
    # skip past the end of block character and any new lines
    while @gerber[@index] is '*' or @gerber[@index] is '\n'
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
          console.log "it's a format command: #{block}"
          @setFormat command
        when 'MO'
          console.log "it's a mode command: #{block}"
          @setMode command
        when 'AD'
          console.log "it's a aperture definition: #{block}"
          @createTool command
        when 'AM'
          console.log "it's a aperture macro: #{block}"
        when 'SR'
          console.log "it's a step repeat command: #{block}"
        when 'LP'
          console.log "it's a level polarity: #{block}"
      # get the check character
      c = @gerber[@index]

    # done with parameter block
    console.log "done with parameter block"
    # push past the trailing % and any newlines
    @index++
    while @gerber[@index] is '\n'
      @line++
      @index++

  # set the format according to the passed command
  setFormat: (command) ->
    console.log "setting format according to #{command}"

    # throw an error if format has already been set
    if @format.set then throw "error at #{line}: format has already been set"

    # leading or trailing omission
    zero = command[0]
    if zero is 'L' or zero is 'T' then @format.zero = zero
    else throw "#{zero} at line #{@line} is invalid zero omission value"

    # coordinate values
    notation = command[1]
    if notation is 'A' or notation is 'I' then @format.notation = notation
    else throw "#{notation} at line #{@line} is invalid notation value"

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
    console.log "zero omission set to: #{@format.zero}, coordinate notation set to: #{@format.notation}, interger places set to #{@format.int}, decimal places set to #{@format.dec}"
    @format.set = true

  # set the unit mode according to the passed command
  setMode: (command) ->
    console.log "setting unit mode according to #{command}"

    # throw an error if mode has already been set
    if @mode.set then throw "error at #{@line}: mode has already been set"

    # set the units
    if command is 'IN'
      @mode.units = 'in'
    else if command is 'MM'
      @mode.units = 'mm'
    else
      throw "#error at {@line}: #{command} is not a valid unit mode"

    # if we get here without throwing an error, change the set flag
    console.log "unit mode set to: #{@mode.units}"
    @mode.set = true

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
        console.log "tool #{toolCode} is a polygon"

      else
        console.lot "tool #{toolCode} might be a macro"

    # create the actual aperture and add it to the tools object
    tool = new Aperture(toolCode, toolShape[0], toolParams)
    @tools[toolCode] = tool

  getCircleToolParams: (command) ->
    numbers = @gatherToolParams command
    # there must be between 1 and 3 numbers
    unless 1 <= numbers.length <= 3 then throw "error at #{line}: circle aperture must have between 1 and 3 params"

    # create the params object with the diameter
    params = {
      dia: numbers[0]
    }
    # hole stuff if it exists
    if numbers[1]? then params.holeX = numbers[1]
    if numbers[2]? then params.holeY = numbers[2]

    # return the params object
    params

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
    if numbers[2]? then params.holeX = numbers[1]
    if numbers[3]? then params.holeY = numbers[2]

    # return the params object
    params

  gatherToolParams: (command) ->
    numbers = command.match /[\+-]?[\d\.]+/g
    # check that the numbers are actually numbers
    for n, i in numbers
      unless n.match /^\+?((\d+\.?\d*)|(\d*\.?\d+))$/ then throw "error at #{line}: #{n} is not a valid number"
      numbers[i] = parseFloat n
    # return the array
    numbers
