# gerber layer model

# render prototype
Render = require './render'

# available layer types and idetifier utility
layerOpts = require '../layer-options'
idLayer = require '../identify-layer'

class Layer extends Render
  defaults: _.extend {
    gerber: ''
    type: 'oth'
    svgObj: null
  }, Render.prototype.defaults

  # on creation, get a default layer type
  initialize: ->
    @setLayerType()
    # once we've got an svgObj, we don't need the gerber file anymore
    # we should also check to make sure we processed, otherwise set to 'oth'
    @once 'change:svgObj', ->
      @unset 'gerber'
      if not Object.keys(@get 'svgObj').length then @set 'type', 'oth'

  setLayerType: -> @set 'type', idLayer @get 'name'

  # validation
  # checks to make sure that if its layer type is singular, that no other models
  # in the collection identify as the same layer
  validate: (attrs, options) ->
    # if the type isn't other and the selected layer type must be singular
    if attrs.type isnt 'oth' and not _.find(layerOpts, {val: attrs.type}).mult
      # pull all the models from the collection with the same layer type
      layers = @collection.where { type: attrs.type }
      return "duplicate layer selection" if layers.length isnt 1
    # return nothing if valid
    return null

module.exports = Layer
