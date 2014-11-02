# unsupported browser error message

canDownload = typeof (document.createElement 'a').download isnt 'undefined'

class UnsupportedView extends Backbone.View
  tagName: 'div'
  className: 'Unsupported'
  
  # cache the template
  template: _.template $('#unsupported-template').html()
  
  events: {
    'click .Unsupported--btn': 'tryAnyway'
  }
  
  render: ->
    @$el.html @template()
    @
  
  # remove the error message and try the app anyway
  tryAnyway: ->
    @$el.remove()

module.exports = UnsupportedView
