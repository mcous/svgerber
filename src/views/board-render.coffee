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
    @listenTo @model, 'render', @render
    # listen for model deletion
    @listenTo @model, 'remove', @remove

  # render function
  render: ->
    svg = @model.get 'svg'
    @$el.html @template {
      name: 'board ' + @model.get 'type'
      img: @model.get 'svg'
    }
    # return this
    if svg.length then @ else @remove()
}
