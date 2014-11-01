# view for board stackup render

module.exports = Backbone.View.extend {
  # dom element is a div item with some classes
  tagName: 'div'
  className: 'BoardContainer'
  # cached template function
  template: _.template $('#board-layer-template').html()

  # initialize with change listener on model
  initialize: ->
    # listen for type changes
    @listenTo @model, 'change:svg change:style', @render
    # listen for model deletion
    @listenTo @model, 'remove', @remove

  # render function
  render: ->
    svg = @model.get 'svg'
    name = @model.get 'name'
    @$el.html @template {
      name: "board #{name}"
      img: svg
      type: name
      href: '#'
    }
    @$el.find('svg').prepend @model.get 'style'
    #@$el.find('svg').attr { width: '100%', height: '100%' }
    # return this
    if svg.length then @ else @model.trigger 'renderRemove'; @remove()

}
