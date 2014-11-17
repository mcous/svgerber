# prototype render view for board and individual layers

canDownload = typeof (document.createElement 'a').download isnt 'undefined'

class RenderView extends Backbone.View
  
  # dom element is a div
  tagName: 'div'
  # cache the template from the dom
  template: _.template $('#board-layer-template').html()
  
  # events
  events: {
    'click .Btn--download': 'handleDownloadClick'
    'click .LayerDrawing': 'handleClick'
  }
  
  # initialize function
  initialize: ->
    # listen for a change on svg64
    @listenTo @model, 'change:svg64', @handleDownloadLink
    # listen for model deletion
    @listenTo @model, 'remove', @remove
    
  # handle a click on the download button
  handleDownloadClick: (e) ->
    if not canDownload
      e.preventDefault()
      e.stopPropagation()
      @handleClick()

  # handle a click on the render itself
  handleClick: (e) ->
    # trigger a show modal event and pass the render model as parameter
    @model.trigger 'openModal', @model
  
  # render and return self
  render: ->
    @$el.html @template {
      name: @model.get 'name'
      img: @model.get 'svg'
    }
    # resize (for ie)
    @resize()
    # return self
    @
    
  # resize
  resize: ->
    svg = @$('svg')[0]
    if svg?
      svgWid = svg.width.baseVal.value
      svgHgt = svg.height.baseVal.value
      ratio = svgHgt/svgWid
      @$('.LayerDrawing').css 'padding-bottom', "#{ratio*100}%"
  
  # download button
  handleDownloadLink: ->
    btn = @$ '.Btn--download'
    # if there is an svg64 available, put it in the button
    svg64 = @model.get 'svg64'
    if svg64
      if canDownload then btn.attr 'href', "data:image/svg+xml;base64,#{svg64}"
      btn.removeClass 'is-disabled'
    # else disable the button
    else
      btn.addClass 'is-disabled'
    
module.exports = RenderView
