# backbone collection of all layers
Layer = require '../models/layer'
module.exports = Backbone.Collection.extend {
  model: Layer

  # attach an event listener on type change
  initialize: ->
    # validate whole collection when a model's layer type gets changed
    @on 'change:type', @validateLayers

  # validate all layer selections
  validateLayers: ->
    # return true to continue even if isValid return false
    @forEach (m) -> if m.isValid() then m.trigger 'valid'; true

}
