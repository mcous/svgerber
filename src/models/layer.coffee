# gerber layer model

# available layer types
layerOptions = require '../layer-options'

module.exports = Backbone.Model.extend {
  defaults: {
    filename: ''
    gerber: ''
    type: 'oth'
    svg: {}
  }

  # on creation, get a default layer type
  initialize: ->
    @setLayerType()

  setLayerType: ->
    console.log 'filename has changed: setting layer type'
    type = 'oth'
    for opt in layerOptions
      if opt.match.test @get 'filename'
        type = opt.val; break
    @set 'type', type
}
