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
    # set the format set flag to false
    @format = {
      set: false
    }

  # plot the layer by reading the gerber file
  plot: ->
    # create a new layer
    layer = new Layer @name
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
    # skip past the end of block character
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
