# a selection of classes for building a circuit board

#require 'aperture.coffee'

# layer object (pad or trace)
class LayerObject
  # constructor takes in the tool shape and parameters
  constructor: (@shape, @params) ->

  # build a


# pad class for Layer
class Pad extends LayerObject

# trace class for Layer
class Trace extends LayerObject
  # constructor

# layer class
class Layer
  constructor: (@name) ->
    @pads = []
    @traces = []

  # add a trace
  addTrace: (@tool, @params)




# export the Board class for node unit testing
if exports? then exports.Layer = Layer
