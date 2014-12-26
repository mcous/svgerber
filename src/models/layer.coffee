# gerber layer model

# render prototype
Render = require './render'

# available layer types and idetifier utility
layerOpts = require '../layer-options'
idLayer = require '../identify-layer'

class Layer extends Render
  defaults: _.extend {
    gerber: ''
    type: 'drw'
    svgObj: null
  }, Render.prototype.defaults

  # on creation, get a default layer type
  initialize: ->
    # once we've got an svgObj, we don't need the gerber file anymore
    # if we're processed, we should also set the layer type
    @once 'change:svgObj', ->
      @unset 'gerber'
      @setLayerType()
    # once we get a warnings array, we should process it
    @once 'change:warnings', ->
      consolidated = {}
      for w in @get 'warnings'
        consolidated[w] = if consolidated[w]? then consolidated[w]+1 else 1
      @set 'warnings', _.map consolidated, (n, w) ->
        w + (if n > 1 then " - x#{n}" else '')
      @trigger 'warningsConsolidated'

  setLayerType: -> 
    @set 'type', 
      if Object.keys(@get 'svgObj').length then idLayer @get 'name' else 'oth'

  # validation
  # checks to make sure that if its layer type is singular, that no other models
  # in the collection identify as the same layer
  validate: (attrs, options) ->
    # if the type isn't other and the selected layer type must be singular
    if attrs.type isnt 'oth' and not _.find(layerOpts, {val: attrs.type}).mult
      # pull all the models from the collection with the same layer type
      layers = @collection.where { type: attrs.type }
      if layers.length isnt 1
        console.log "#{attrs.name} failed validation with #{attrs.type}"
        return "duplicate layer selection" 
    # return nothing if valid
    return null

module.exports = Layer
