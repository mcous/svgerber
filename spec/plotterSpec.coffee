# jasmine specs for the Plotter class

plotter = require '../coffee/plotter.coffee'
fs = require 'fs'
testGerber = fs.readFileSync("testgerber/test.gbr", {encoding: 'UTF-8'})

describe 'Test gerber file', ->
  it 'should be a string', ->
    expect(typeof(testGerber)).toBe "string"

describe 'Plotter class', ->

  p = null
  beforeEach ->
    p = new plotter.Plotter(testGerber)

  describe 'constructor', ->
    it 'constructor should split the file string into an array', ->
      result = Array.isArray(p.gerber)
      expect(result).toBe true

    it 'constructor should strip out comments', ->
      p = new plotter.Plotter("G04 this is a gerber comment*")
      result = p.gerber.length
      expect(result).toBe 0

      p = new plotter.Plotter("This is not a gerber comment")
      result = p.gerber.length
      expect(result).toBe 1

  describe 'format identification', ->
    leadSuppression  = "%FSLAX34Y34*%"
    trailSuppression = "%FSTAX34Y34*%"
    noSuppression    = "%FSAX34Y34*%"
    absCoordinates   = "%FSLAX34Y34*%"
    incCoordinates   = "%FSLIX34Y34*%"
    noCoordinates    = "%FSLX34Y34*%"
    threeFour        = "%FSLAX34Y34*%"
    sevenSeven       = "%FSLAX77Y77*%"
    eightEight       = "%FSLAX88Y88*%"
    zeroSix          = "%FSLAX06Y06*%"
    noneNone         = "%FSLA*%"
    noX              = "%FSLAY77*%"
    noY              = "%FSLAX77*%"
    mismatch         = "%FSLAX34Y56*%"

    it 'should throw an error if the format spec is not the first line', ->
      p = new plotter.Plotter("not a format spec\nalso not a fs")
      result = "NoErrorCaught"
      try
        p.getFormatSpec()
      catch error
        result = error
      expect(result).toBe "FirstNonCommentNotFormatSpecError"

    describe 'zero omission', ->
      it 'should identify the zero omission', ->
        p = new plotter.Plotter(leadSuppression)
        p.getFormatSpec()
        result = p.zeroOmit
        expect(result).toBe "L"

        p = new plotter.Plotter(trailSuppression)
        p.getFormatSpec()
        result = p.zeroOmit
        expect(result).toBe "T"

      it 'should throw an error if no zero suppression is defined', ->
        p = new plotter.Plotter(noSuppression)
        result = "NoErrorCaught"
        try
          p.getFormatSpec()
        catch error
          result = error
        expect(result).toBe "NoZeroSuppressionInFormatSpecError"

    describe 'coordinate notation', ->
      it 'should identify absolute or incremental coordinates', ->
        p = new plotter.Plotter(absCoordinates)
        p.getFormatSpec()
        result = p.notation
        expect(result).toBe "A"

        p = new plotter.Plotter(incCoordinates)
        p.getFormatSpec()
        result = p.notation
        expect(result).toBe "I"

      it 'should thrown an error if abs or inc notation is not defined', ->
        p = new plotter.Plotter(noCoordinates)
        result = "NoErrorCaught"
        try
          p.getFormatSpec()
        catch error
          result = error
        expect(result).toBe "NoCoordinateNotationInFormatSpecError"

    describe 'coordinate format', ->
      it 'should identify the number format for x and y', ->
        p = new plotter.Plotter(threeFour)
        p.getFormatSpec()
        result = [p.leadDigits, p.trailDigits]
        expect(result[0]).toBe 3
        expect(result[1]).toBe 4

        p = new plotter.Plotter(sevenSeven)
        p.getFormatSpec()
        result = [p.leadDigits, p.trailDigits]
        expect(result[0]).toBe 7
        expect(result[1]).toBe 7

      it 'should throw an error if the number formats are invalid', ->
        p = new plotter.Plotter(eightEight)
        result = "NoErrorCaught"
        try
          p.getFormatSpec()
        catch error
          result = error
        expect(result).toBe "InvalidCoordinateFormatInFormatSpecError"

        p = new plotter.Plotter(zeroSix)
        result = "NoErrorCaught"
        try
          p.getFormatSpec()
        catch error
          result = error
        expect(result).toBe "InvalidCoordinateFormatInFormatSpecError"


      it 'should throw an error if the number formats are different', ->
        p = new plotter.Plotter(mismatch)
        result = "NoErrorCaught"
        try
          p.getFormatSpec()
        catch error
          result = error
        expect(result).toBe "CoordinateFormatMismatchInFormatSpecError"

      it 'should throw an error if the number format is missing', ->
        p = new plotter.Plotter(noX)
        result = "NoErrorCaught"
        try
          p.getFormatSpec()
        catch error
          result = error
        expect(result).toBe "MissingCoordinateFormatInFormatSpecError"

        p = new plotter.Plotter(noY)
        result = "NoErrorCaught"
        try
          p.getFormatSpec()
        catch error
          result = error
        expect(result).toBe "MissingCoordinateFormatInFormatSpecError"

        p = new plotter.Plotter(noneNone)
        result = "NoErrorCaught"
        try
          p.getFormatSpec()
        catch error
          result = error
        expect(result).toBe "MissingCoordinateFormatInFormatSpecError"

  describe 'unit identification', ->
