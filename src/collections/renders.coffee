# prototype collection for individual layers as well as board stackup renders

# require gerber converter and base64 workers
converter = new Worker './../workers/gerber-worker.coffee'
encoder = new Worker './../workers/btoa-worker.coffee'

class Renders extends Backbone.Collection
  
  initialize: ->
    # attach handlers to the workers
    @attachConverterHandler()
    @attachEncoderHandler()
    # encode the svg if the svg string changes
    @on 'change:svg', @encode
    
  encode: (render) ->
    encoder.postMessage { name: render.get 'name', string: render.get 'svg' }
    
  convert: (name, gerber) ->
    converter.postMessage { filename: name, gerber: gerber }  
  
  # attach a handler for when the base64 worker finishes
  attachEncoderHandler: ->
    _self = @
    handler = (e) ->
      if render = _self.findWhere { name: e.data.name }
        render.set 'svg64', e.data.string
    encoder.addEventListener 'message', handler, false

  # attach a handler for when the gerber worker finishes
  # this will fire in all collections, so beware of the effects that has
  attachConverterHandler: ->
    _self = @
    handler = (e) ->
      # if render exists
      if render = _self.findWhere { name: e.data.filename }
        render.set 'svgObj', e.data.svgObj
        render.set 'svg', e.data.svgString
        render.trigger 'processEnd', render
    converter.addEventListener 'message', handler, false

module.exports = Renders
