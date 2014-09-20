# backbone model of a board stackup

# requires the layer collection and options
LayerList = require '../collections/layers'
layerOptions = require '../layer-options'

# watches a layer collection
module.exports = Backbone.Model.extend {
  defaults: {
    boardLayers: {}
    type: ''
    svg: ''
  }

  initialize: ->
    layers = @get 'layers'
    # listen for changes in the layers, and trigger a new board event
    @listenTo layers, 'change:type change:svgString', @handleLayersChange
    # also listen to add and remove events, but debounce them by 10ms
    @listenTo layers, 'add remove', _.debounce @handleLayersChange, 10

  getBoardLayers: ->
    # filter out the layers
    type = @get 'type'
    boardLayers = @get('layers').filter (layer) ->
      opt = _.find layerOptions, { val: layer.get 'type' }
      # return true if the board side of the option matches the board type
      opt?.side is type or opt?.side is 'both'
    # set layers
    @set 'boardLayers', _.map boardLayers, (ly) ->
      { type: ly.get('type'), svgObj: ly.get('svgObj') }
    # set mult layers
    # trigger a build needed event
    @trigger 'buildNeeded', @

  handleLayersChange: ->
    layers = @get 'layers'
    # if there are layers and they passes validation
    if layers.validateLayers()
      # and the lenth of the collection matches the number of processed layers
      processed = (layers.filter (layer) -> layer.get('svgObj')?) ? []
      if layers.length is processed.length
        # get the board layers and trigger a build
        @getBoardLayers()
    # return false?
    false
}
