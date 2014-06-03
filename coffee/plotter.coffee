# plotter class for svgerber
# constructor takes in gerber file as string

# export the class for node or browser
root = exports #? this

class root.Plotter
  constructor: (gerberFile) ->
    # parse the monolithic string into an array of lines
    gerberFile = gerberFile.split '\n'
    # strip out the comments
    @gerber = []
    for line in gerberFile
      @gerber.push(line) unless line.match(/^G04/)
    # notify those concerned
    console.log "Plotter class created"

  getFormatSpec: ->
    formatMatch = /^%FS.*\*%$/  # file spec regex
    zeroMatch = /[LT]/          # leading or trailing zeros omitted
    notationMatch = /[AI]/      # Absolute or incremental notation
    xDataMatch = /X+?\d{2}/  # x data format
    yDataMatch = /Y+?\d{2}/  # y data format

    fS = @gerber[0]
    @zeroOmit = null
    @notation = null
    @leadDigits = null
    @trailDigits = null

    # check that the file format spec is the first line
    if not fS.match(formatMatch)
      throw "FirstNonCommentNotFormatSpecError"
    # else we've got a file format. start parsing stuff
    else
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
