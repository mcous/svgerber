# modal board view for zoomed viewing and download

canDownload = typeof (document.createElement 'a').download isnt 'undefined'

class ModalView extends Backbone.View
  tagName: 'div'
  className: 'Modal'
  
  # cache the template
  template: _.template $('#modal-template').html()
  
  events: {
    'click': 'handleClick'
  }
  
  # initalize with modal closed
  initialize: ->
    @closeModal()
  
  # render
  render: (render) ->
    svg64 = render?.get 'svg64'
    @$el.html @template {
      name: render?.get 'name'
      src: if svg64? then "data:image/svg+xml;base64,#{svg64}" else ''
      canDownload: canDownload
    }
    @resize()
    # return self
    @
    
  # size the image properly depending on window size
  resize: =>
    hgt = @$el.height()
    wid = @$el.width()
    img = @$ '.Modal--img'
    imgHgt = img.height()
    imgWid = img.width()
    if hgt/imgHgt < wid/imgWid then img.height(0.9*hgt) else img.width(0.9*wid)
    
  # show the modal unhiding the modal (to allow size calcs), then render it
  openModal: (render) ->
    @$el.removeClass 'is-hidden'
    @render render
    
  # close the modal by hiding it
  closeModal: -> @$el.addClass 'is-hidden'
  
  # handle a click
  handleClick: -> @closeModal()
  
module.exports = ModalView
