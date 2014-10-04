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
    @$el.html @template {
      name: 'board ' + @model.get 'type'
      img: @model.get 'svg'
      type: @model.get 'type'
      href: '#'
    }
    @$el.find('svg').prepend @model.get 'style'
    #@$el.find('svg').attr { width: '100%', height: '100%' }
    # return this
    if svg.length then @ else @model.trigger 'renderRemove'; @remove()

}
