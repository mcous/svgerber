# backbone view for a filelist item

# require the gerber layer options
layerOptions = require '../layer-options'

module.exports = Backbone.View.extend {
  # dom element is a list item with some classes
  tagName: 'li'
  className: 'UploadList--item'
  # cached template function
  template: _.template $('#filelist-item-template').html()

  # events
  events: {
    # delete button
    'click .UploadList--itemDelete': 'removeLayer'
    # layer select
    'change .UploadList--SelectMenu': 'changeLayerType'
    # don't let a click on the select menu bubble up the DOM
    'click .UploadList--SelectMenu': (e) -> e.stopPropagation()
    # click on item
    'click': 'showWarnings'
  }

  initialize: ->
    # delete self on model deletion
    @listenTo @model, 'remove', @remove
    # listen for type changes
    @listenTo @model, 'change:type', @renderType
    # attach event listener to model for validations
    @listenTo @model, 'valid invalid', @renderValidation
    # attach event listener to process and processend events
    @listenToOnce @model, 'processEnd', @renderProcessing
    # attach listener to warningsConsolidated event
    @listenToOnce @model, 'warningsConsolidated', @renderWarnings

  renderValidation: ->
    icon = @$el.find '.UploadList--selectIcon'
    if @model.validationError
      @$el.removeClass('is-valid').addClass 'is-invalid'
      @changeIcon icon, 'octicon-circle-slash'
    else
      @$el.removeClass('is-invalid').addClass 'is-valid'
      @changeIcon icon, 'octicon-chevron-right'

  renderProcessing: ->
    # default value is null, so if there's an object we're done
    if @model.get('svgObj')?
      @$el.removeClass 'is-processing'
      # if the svg came back, empty, though, there was a processing error
      if not @model.get 'svg'
        @$el.addClass 'is-unprocessable'
        @$el.find('.UploadList--text').html 'did not process'
        @$el.find('select.UploadList--SelectMenu').remove()
    else
      @$el.addClass 'is-processing'

  renderWarnings: ->
    warnings = @model.get 'warnings'
    if warnings.length
      @$el.addClass 'is-warned'
      ul = @$('.UploadList--itemWarnings')
      ul.html ("<li>#{w}</li>" for w in warnings)
      @$('.UploadList--warningIcon').removeClass 'is-hidden'

  showWarnings: ->
    if @model.get('warnings').length
      @$('.UploadList--itemWarningsContainer').toggleClass 'is-retracted'

  # render method
  render: ->
    @$el.html @template {
      filename: @model.get 'name'
      type: @model.get 'type'
      options: layerOptions
    }
    # set the type
    @renderType()
    # set the valid class
    @renderValidation()
    # set the processing class
    @renderProcessing()
    # return this
    return @

  # render the type selection
  renderType: ->
    # select the correct option according to the model
    @$el.find("option[value='#{@model.get 'type'}']").prop 'selected', true

  # remove layer
  removeLayer: ->
    # detach event listeners
    @undelegateEvents()
    # shrink to zero height and then remove model from the collection
    model = @model
    @$el.animate { height: 0 }, {
      duration: 100
      queue: false
      easing: 'linear'
      # remove the model from the collection
      complete: -> model.collection.remove model
    }

  # change the layer type
  changeLayerType: ->
    @model.set 'type', @$el.find('option:selected').attr 'value'

  # change icon helper
  changeIcon: (element, newIcon) ->
    element.removeClass( (i, c) -> c.match(/octicon-\S+/g)?.join ' ')
      .addClass newIcon

}
