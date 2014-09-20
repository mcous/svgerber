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
    # listen for changes in the layers, and trigger a new board event
    @listenTo @get('layers'), 'change', @handleLayersChange

  getBoardLayers: ->
    # filter out the layers
    type = @get 'type'
    boardLayers = @get('layers').filter (layer) ->
      opt = _.find layerOptions, { val: layer.get 'type' }
      # return true if the board side of the option matches the board type
      opt?.side is type or opt?.side is 'both'
    # set singular layers
    @set 'boardLayers', _.map boardLayers, (ly) ->
      { type: ly.get('type'), svgObj: ly.get('svgObj') }
    console.log @get 'boardLayers'
    # set mult layers
    # trigger a build needed event
    @trigger 'buildNeeded', @

  handleLayersChange: ->
    layers = @get 'layers'
    # if there are layers and they passes validation
    if layers.length and layers.validateLayers()
      # and the lenth of the collection matches the number of processed layers
      processed = (layers.filter (layer) -> layer.get('svgObj')?) ? []
      if layers.length is processed.length
        # get the board layers and trigger a build
        @getBoardLayers()

}
