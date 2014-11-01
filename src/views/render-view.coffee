# prototype render view for board and individual layers

class RenderView extends Backbone.View
  
  # dom element is a div
  tagName: 'div'
  # cache the template from the dom
  template: _.template $('#board-layer-template').html()
  
  # events
  events: {
    'click a.LayerDrawing': 'handleClick'
  }
  
  # initialize function
  initialize: ->
    # listen for a change on svg64
    @listenTo @model, 'change:svg64', @handleDownloadLink
    # listen for model deletion
    @listenTo @model, 'remove', @remove
    
  # handle a click
  handleClick: (e) ->
    e.preventDefault()
    e.stopPropagation()
  
  # render and return self
  render: ->
    @$el.html @template {
      name: @model.get 'name'
      img: @model.get 'svg'
    }
    @
    
  # download button
  handleDownloadLink: ->
    btn = @$ '.Btn--download'
    # if there is an svg64 available, put it in the button
    svg64 = @model.get 'svg64'
    if svg64
      btn.attr 'href', "data:image/svg+xml;base64,#{svg64}"
      btn.removeClass 'is-disabled'
    # else disable the button
    else
      btn.addClass 'is-disabled'
    
module.exports = RenderView
