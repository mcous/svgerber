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

  it 'constructor should split the file string into an array', ->
    result = Array.isArray(p.gerber)
    expect(result).toBe true
