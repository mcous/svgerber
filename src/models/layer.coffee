# gerber layer model

# available layer types
layerOpts = require '../layer-options'
# converter
#Gerber = require '../convert-gerber'

module.exports = Backbone.Model.extend {
  defaults: {
    filename: ''
    gerber: ''
    type: 'oth'
    svgObj: null
    svgString: null
  }

  # on creation, get a default layer type
  initialize: ->
    @setLayerType()
    # once we've got an svgObj, we don't need the gerber file anymore
    @once 'change:svgObj', -> @unset 'gerber'

  setLayerType: ->
    type = 'drw'
    for opt in layerOpts
      if opt.match.test @get 'filename'
        type = opt.val; break
    @set 'type', type

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


}
