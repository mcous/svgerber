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

  # tests for the plotter constructor
  describe 'constructor', ->
    it 'constructor should split the file into an array', ->
      result = Array.isArray(p.gerber)
      expect(result).toBe true

  # tests for parsing the format spec command
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

  # tests for parsing the unit set command
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

  # tests for parsing the aperture definition command
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
            result = "NoErrorCaught"
            try
              p.parseAperture(bad)
            catch error
              result = error
            expect(result).toBe "BadCircleApertureError"

      describe 'rectangles', ->
        goodRects = [
          "%ADD22R,0.044X0.025*%"
          "%ADD22R,0.044X0.025X0.019*%"
          "%ADD22R,0.044X0.025X0.024X0.013*%"
        ]
        badRects = [
          "%ADD22R,0.044*%"
          "%ADD22R0.044X0.025X0.019*%"
          "%ADD22R,0.044X0.025X0.024X0.013X0.04*%"
        ]

        it 'should set aperture to rectangle if given a good input', ->
          for good in goodRects
            result = p.parseAperture(good)
            result = result.shape
            expect(result).toBe 'R'

        it 'should pass in parameters properly', ->
          result = p.parseAperture goodRects[0]
          result = result.params
          expect(result[0]).toBe 0.044
          expect(result[1]).toBe 0.025

          result = result = p.parseAperture goodRects[2]
          result = result.params
          expect(result[0]).toBe 0.044
          expect(result[1]).toBe 0.025
          expect(result[2]).toBe 0.024
          expect(result[3]).toBe 0.013

        it 'should throw an error if bad rectangle', ->
          for bad in badRects
            result = "NoErrorCaught"
            try
              p.parseAperture(bad)
            catch error
              result = error
            expect(result).toBe "BadRectangleApertureError"

      describe 'obrounds', ->
        goodObrounds = [
          "%ADD22O,0.044X0.025*%"
          "%ADD22O,0.044X0.025X0.019*%"
          "%ADD22O,0.044X0.025X0.024X0.013*%"
        ]
        badObrounds = [
          "%ADD22O,0.044*%"
          "%ADD22O0.044X0.025X0.019*%"
          "%ADD22O,0.044X0.025X0.024X0.013X0.04*%"
        ]

        it 'should set aperture to obround if given a good input', ->
          for good in goodObrounds
            result = p.parseAperture(good)
            result = result.shape
            expect(result).toBe 'O'

        it 'should pass in parameters properly', ->
          result = p.parseAperture goodObrounds[0]
          result = result.params
          expect(result[0]).toBe 0.044
          expect(result[1]).toBe 0.025

          result = result = p.parseAperture goodObrounds[2]
          result = result.params
          expect(result[0]).toBe 0.044
          expect(result[1]).toBe 0.025
          expect(result[2]).toBe 0.024
          expect(result[3]).toBe 0.013

        it 'should throw an error if bad obround', ->
          for bad in badObrounds
            result = "NoErrorCaught"
            try
              p.parseAperture(bad)
            catch error
              result = error
            expect(result).toBe "BadObroundApertureError"

  # tests for running through the gerber file
  describe 'plotting', ->
    it 'should complain if no format spec', ->
      badGerber = """
        %MOIN*%
        %ADD10C,0.006000*%
        %ADD11C,0.003937*%
      """
      p = new plotter.Plotter(badGerber)
      result = "NoErrorCaught"
      try
        p.plot()
      catch error
        result = error
      expect(result).toBe "NoFormatSpecGivenError"

    it 'should complain if no unit spec', ->
      badGerber = """
        %FSLAX34Y34*%
        %ADD10C,0.006000*%
        %ADD11C,0.003937*%
      """

      p = new plotter.Plotter(badGerber)
      result = "NoErrorCaught"
      try
        p.plot()
      catch error
        result = error
      expect(result).toBe "NoValidUnitsGivenError"

    it 'should not allow redefinition of apertures', ->
      badGerber = """
        %FSLAX34Y34*%
        %MOIN*%
        %ADD10C,0.006000*%
        %ADD10C,0.003937*%
      """
      p = new plotter.Plotter(badGerber)
      result = "NoErrorCaught"
      try
        p.plot()
      catch error
        result = error
      expect(result).toBe "ApertureAlreadyExistsError"

    it 'should add apertures to the list without problem', ->
      goodGerber ="""
        %FSLAX34Y34*%
        %MOIN*%
        %ADD10C,0.006000*%
        %ADD11C,0.003937*%
        %ADD30C,0.003937*%
      """

      p = new plotter.Plotter(badGerber)
      result = p.apertures
      expect(result[0].code).toBe 10
      expect(result[1].code).toBe 11
      expect(result[20].code).toBe 30



  # tests for parsing a line that starts with a G-code
  describe 'G-code parsing', ->
    it 'should throw an error if passed a bad string', ->
      badString = ""
      result = "NoErrorCaught"
      try
        p.parseGCode badString
      catch error
        result = error
      expect(result).toBe "InputTo_parseGCode_NotAGCodeError"

      badString = "G001"
      result = "NoErrorCaught"
      try
        p.parseGCode badString
      catch error
        result = error
      expect(result).toBe "InputTo_parseGCode_NotAGCodeError"

    it 'should return the string with the G command stripped out', ->
      g = "G01X0Y250D01*"
      result = p.parseGCode g
      expect(result).toBe "X0Y250D01*"

    it 'should set mode to linear interpolation if it sees a G01 or G1', ->
      g = "G01X0Y250D01*"
      p.parseGCode g
      result = p.iMode
      expect(result).toBe 1

      g = "G1X0Y250D01*"
      p.parseGCode g
      result = p.iMode
      expect(result).toBe 1

    it 'should set mode to circular interp. (CW or CCW) if G2/02, G3/03', ->
      g = "G02X0Y250D01*"
      p.parseGCode g
      result = p.iMode
      expect(result).toBe 2

      g = "G2X0Y250D01*"
      p.parseGCode g
      result = p.iMode
      expect(result).toBe 2

      g = "G03X0Y250D01*"
      p.parseGCode g
      result = p.iMode
      expect(result).toBe 3

      g = "G3X0Y250D01*"
      p.parseGCode g
      result = p.iMode
      expect(result).toBe 3

    it 'should return an empty string if G4/04 (comment)', ->
      g="G04 gerber comments ftwzzzzzz"
      result = p.parseGCode g
      expect(result).toBe ""

    it 'should set the arc mode to 74 or 75 if given the G74/75 command', ->
      g="G74*"
      p.parseGCode g
      result = p.aMode
      expect(result).toBe 74

      g="G75*"
      p.parseGCode g
      result = p.aMode
      expect(result).toBe 75
