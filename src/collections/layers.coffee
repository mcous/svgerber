# backbone collection of all layers
Layer = require '../models/layer'
# gerber converter worker
converter = new Worker './../gerber-worker.coffee'

module.exports = Backbone.Collection.extend {
  model: Layer
  # attach an event listener on type change
  initialize: ->
    # validate whole collection when a model's layer type gets changed
    @on 'change:type', @validateLayers
    # attach an event listener to the converter
    @addConverterHandler()
    # when a model is added, convert it
    @on 'add', (layer) -> converter.postMessage {
      filename: layer.get 'filename'
      gerber: layer.get 'gerber'
    }

  # validate all layer selections
  validateLayers: ->
    # return true to continue even if isValid return false
    @forEach (layer) -> if layer.isValid() then layer.trigger 'valid'; true

  # convert a gerber to an svg object
  addConverterHandler: ->
    _this = @
    handler = (e) ->
      layer = _this.findWhere { filename: e.data.filename }
      layer.set 'svgObj', e.data.svgObj
      layer.set 'svgString', e.data.svgString
      layer.trigger 'processEnd', layer
    converter.addEventListener 'message', handler, false

}
