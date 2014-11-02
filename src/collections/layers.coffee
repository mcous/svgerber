# collection of all individual layers
# require Layer model and Renders prototype collection
Layer = require '../models/layer'
Renders = require './renders'

class Layers extends Renders
  model: Layer
  
  # attach an event listener on type change
  initialize: ->
    # validate whole collection when a model's layer type gets changed
    @on 'change:type', @validateLayers
    # when a model is added, convert it
    @on 'change:gerber', (layer) ->
      gerber = layer.get 'gerber'
      if gerber then @convert layer.get('name'), gerber
    # call the super
    super()

  # validate all layer selections
  validateLayers: ->
    valid = true
    # return true to continue even if isValid return false
    @forEach (layer) ->
      if layer.isValid() then layer.trigger 'valid' else valid = false
      # return true to keep validating
      true
    # return the validation
    valid

module.exports = Layers
