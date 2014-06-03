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

    # it 'constructor should strip out comments', ->
    #   p = new plotter.Plotter("G04 this is a gerber comment*")
    #   result = p.gerber.length
    #   expect(result).toBe 0
    #
    #   p = new plotter.Plotter("This is not a gerber comment")
    #   result = p.gerber.length
    #   expect(result).toBe 1

  describe 'format parsing', ->
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

    it 'should throw an error if given bad input', ->
      result = "NoErrorCaught"
      try
        p.parseFormatSpec "asdafreaewr"
      catch error
        result = error
      expect(result).toBe "InputTo_parseFormatSpec_NotAFormatSpecError"


    describe 'zero omission', ->
      it 'should identify the zero omission', ->
        p.parseFormatSpec(leadSuppression)
        result = p.zeroOmit
        expect(result).toBe "L"

        p.parseFormatSpec(trailSuppression)
        result = p.zeroOmit
        expect(result).toBe "T"

      it 'should throw an error if no zero suppression is defined', ->
        result = "NoErrorCaught"
        try
          p.parseFormatSpec(noSuppression)
        catch error
          result = error
        expect(result).toBe "NoZeroSuppressionInFormatSpecError"

    describe 'coordinate notation', ->
      it 'should identify absolute or incremental coordinates', ->
        p.parseFormatSpec(absCoordinates)
        result = p.notation
        expect(result).toBe "A"

        p.parseFormatSpec(incCoordinates)
        result = p.notation
        expect(result).toBe "I"

      it 'should thrown an error if abs or inc notation is not defined', ->
        result = "NoErrorCaught"
        try
          p.parseFormatSpec(noCoordinates)
        catch error
          result = error
        expect(result).toBe "NoCoordinateNotationInFormatSpecError"

    describe 'coordinate format', ->
      it 'should identify the number format for x and y', ->
        p.parseFormatSpec(threeFour)
        result = [p.leadDigits, p.trailDigits]
        expect(result[0]).toBe 3
        expect(result[1]).toBe 4

        p.parseFormatSpec(sevenSeven)
        result = [p.leadDigits, p.trailDigits]
        expect(result[0]).toBe 7
        expect(result[1]).toBe 7

      it 'should throw an error if the number formats are invalid', ->
        result = "NoErrorCaught"
        try
          p.parseFormatSpec(eightEight)
        catch error
          result = error
        expect(result).toBe "InvalidCoordinateFormatInFormatSpecError"

        result = "NoErrorCaught"
        try
          p.parseFormatSpec(zeroSix)
        catch error
          result = error
        expect(result).toBe "InvalidCoordinateFormatInFormatSpecError"


      it 'should throw an error if the number formats are different', ->
        result = "NoErrorCaught"
        try
          p.parseFormatSpec(mismatch)
        catch error
          result = error
        expect(result).toBe "CoordinateFormatMismatchInFormatSpecError"

      it 'should throw an error if the number format is missing', ->
        result = "NoErrorCaught"
        try
          p.parseFormatSpec(noX)
        catch error
          result = error
        expect(result).toBe "MissingCoordinateFormatInFormatSpecError"

        result = "NoErrorCaught"
        try
          p.parseFormatSpec(noY)
        catch error
          result = error
        expect(result).toBe "MissingCoordinateFormatInFormatSpecError"

        result = "NoErrorCaught"
        try
          p.parseFormatSpec(noneNone)
        catch error
          result = error
        expect(result).toBe "MissingCoordinateFormatInFormatSpecError"

  describe 'unit parsing', ->
    millimeters = "%MOMM*%"
    inches      = "%MOIN*%"
    badUnits    = "%MOKM*%"
    noUnits     = ""

    it 'should get the units', ->
      p.parseUnits(inches)
      result = p.units
      expect(result).toBe "IN"

      p.parseUnits(millimeters)
      result = p.units
      expect(result).toBe "MM"

    it 'should throw an error if no proper units are given', ->
      result = "NoErrorCaught"
      try
        p.parseUnits(badUnits)
      catch error
        result = error
      expect(result).toBe "NoValidUnitsGivenError"

      result = "NoErrorCaught"
      try
        p.parseUnits(noUnits)
      catch error
        result = error
      expect(result).toBe "NoValidUnitsGivenError"

  describe 'aperture definition parsing', ->
    # test aperture
    testAp  = "%ADD10C,0.006000*%"

    it 'should throw an error if passed bad input', ->
      result = "NoErrorCaught"
      try
        p.parseAperture("")
      catch error
        result = error
      expect(result).toBe "InputTo_parseAperture_NotAnApertureError"

    it 'should return an aperture class', ->
      result = p.parseAperture(testAp)
      result = result.constructor.name
      expect(result).toBe "Aperture"

    describe 'tool code', ->
      badCodes = [
        "%ADD1C,0.006000*%"
        "%ADD00C,0.006000*%"
        "%ADD01C,0.006000*%"
        "%ADC,0.006000*%"
      ]

      it 'should assign the proper tool code', ->
        result = p.parseAperture(testAp)
        result = result.code
        expect(result).toBe 10

      it 'should throw an error if no or bad tool code', ->
        for bad in badCodes
          result = "NoErrorCaught"
          try
            p.parseAperture(bad)
          catch error
            result = error
          expect(result).toBe "InvalidApertureToolCodeError"

    describe 'aperture shape', ->
      noShape = "%ADD10*%"

      it 'should throw an error if there is no shape data', ->
        result = "NoErrorCaught"
        try
          p.parseAperture(noShape)
        catch error
          result = error
        expect(result).toBe "NoApertureShapeError"

      describe 'circles', ->
        goodCircles = [
          "%ADD10C,0*%"
          "%ADD10C,.025*%"
          "%ADD10C,0.5*%"
          "%ADD10C,0.5X0.25*%"
          "%ADD10C,0.5X0.29X0.29*%"
        ]
        badCircles = [
          "%ADD10C.025*%"
          "%ADD10C,0.5X0.29X0.29X0.65*%"
          "%ADD10C,0.5X0.2.9X0.29*%"
        ]

        it 'should set aperture to circle if given a good circle input', ->
          for good in goodCircles
            result = p.parseAperture(good)
            result = result.shape
            expect(result).toBe 'C'

        it 'should pass in parameters properly', ->
          result = p.parseAperture goodCircles[0]
          result = result.params[0]
          expect(result).toBe 0

          result = result = p.parseAperture goodCircles[4]
          result = result.params
          expect(result[0]).toBe 0.5
          expect(result[1]).toBe 0.29
          expect(result[2]).toBe 0.29

        it 'should throw an error if bad circle', ->
          for bad in badCircles
            console.log "testing bad circle: " + bad
            result = "NoErrorCaught"
            try
              p.parseAperture(bad)
            catch error
              result = error
            expect(result).toBe "BadCircleApertureError"

    #
    # it 'should parse a circular aperture', ->
    #   p.parseAperture
    #
    # it 'should throw an error for an incorrect circular aperture', ->
