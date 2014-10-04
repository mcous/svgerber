# view for individual board layer

# require the gerber layer options
layerOptions = require '../layer-options'

module.exports = Backbone.View.extend {
  # dom element is a div item with some classes
  tagName: 'div'
  className: 'LayerContainer'
  # cached template function
  template: _.template $('#board-layer-template').html()

  events: {
    'click a.LayerDrawing': 'handleClick'
  }

  # initialize with change listener on model
  initialize: ->
    # listen for type changes
    @listenTo @model, 'change:type', @renderTitle
    # listen for model deletion
    @listenTo @model, 'remove', @remove

  # change the title
  renderTitle: ->
    @$el.find('.LayerHeading').html(
      _.find(layerOptions, { val: @model.get 'type' }).desc
    )

  # render function
  render: ->
    @$el.html @template {
      name: _.find(layerOptions, { val: @model.get 'type' })?.desc
      img: @model.get 'svgString'
      type: @model.get 'type'
      href: '#'
    }
    # return this
    @

  # encode for download and trigger download
  download: ->
    a = @$el.children 'a.LayerDrawing'
    a.attr 'href', btoa @model.get 'svgString'
    console.log a.attr 'href'
    a.trigger 'click'

  # handle a click
  handleClick: (e) ->
    if @$el.children('a.LayerDrawing').attr('href') is '#'
      e.preventDefault()
      e.stopPropagation()
      @download()
}
