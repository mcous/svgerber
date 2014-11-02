# view for board stackup render
# extends render view
RenderView = require './render-view'

class BoardView extends RenderView

  className: 'BoardContainer'

  # initialize with change listener on model
  initialize: ->
    # call super
    super()
    # listen for type changes
    @listenTo @model, 'change:svg change:style', @render

  # render function
  render: ->
    super()
    svg = @model.get 'svg'
    @$('.LayerTitle').html "board #{@model.get 'name'}"
    @$('svg').prepend @model.get 'style'
    # return this
    if svg.length then @ else @model.trigger 'renderRemove'; @remove()

module.exports = BoardView
