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
  }

  initialize: ->
    # attach event listener to model for validations
    @listenTo @model, 'valid invalid', @renderValidation
    # attach event listener to process and processend events
    @listenToOnce @model, 'processEnd', @renderProcessing

  renderValidation: ->
    if @model.validationError
      @$el.removeClass('is-valid').addClass 'is-invalid'
    else
      @$el.removeClass('is-invalid').addClass 'is-valid'

  renderProcessing: ->
    # default value is null, so if there's an object we're done
    if @model.get('svgObj')?
      @$el.removeClass 'is-processing'
      # if the svg came back, empty, though, there was a processing error
      if not @model.get 'svgString'
        @$el.addClass 'is-unprocessable'
        @$el.find('.UploadList--text').html 'did not process'
        @$el.find('select.UploadList--SelectMenu').remove()
    else
      @$el.addClass 'is-processing'

  # render method
  render: ->
    @$el.html @template {
      filename: @model.get 'filename'
      type: @model.get 'type'
      options: layerOptions
    }
    # select the correct option according to the model
    @$el.find("option[value='#{@model.get 'type'}']").prop 'selected', true
    # set the valid class
    @renderValidation()
    # set the processing class
    @renderProcessing()
    # return this
    return @

  # remove layer
  removeLayer: ->
    # delete the dom element
    @$el.remove()
    # remove the model from the collection
    @model.collection.remove @model

  # change the layer type
  changeLayerType: ->
    @model.set 'type', @$el.find('option:selected').attr 'value'

}
