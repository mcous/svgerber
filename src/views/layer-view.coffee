# view for individual board layer
# requires render view and gerber layer options
RenderView = require './render-view'
layerOptions = require '../layer-options'

class LayerView extends RenderView
  
  className: 'LayerContainer'

  # initialize with change listener on model
  initialize: ->
    # call super
    super()
    # listen for type changes
    @listenTo @model, 'change:type', @renderTitle

  # change the title
  renderTitle: ->
    @$('.LayerTitle').html(
      _.find(layerOptions, { val: @model.get 'type' }).desc
    )

  # render function
  render: ->
    # call parent render, fix title, and return self
    super()
    @renderTitle()
    @

module.exports = LayerView
