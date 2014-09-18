# svgerber backbone app

# require our other views
FilelistItemView = require './filelist-item.coffee'

# create a layers collection
LayerList = require '../collections/layers'
layers = new LayerList()

module.exports = Backbone.View.extend {
  el: '#svgerber-app'

  # app events
  events: {
    # file upload events
    # drop in dropzone
    'drop #dropzone': 'handleFileSelect'
    # manual file select
    'change #upload-select': 'handleFileSelect'
    # load samples when the sample button is clicked
    'click #sample-btn': 'loadSamples'
  }

  initialize: ->
    # log so I don't go insane
    console.log 'svgerber app started'
    # listen to the layers collection for changes
    @listenTo layers, 'add', @addLayer

  # add a gerber layer
  addLayer: ( layer ) ->
    # add to the filelist
    view = new FilelistItemView { model: layer }
    $('#filelist').append view.render().el

  # handle a file select
  # take care of a file event
  handleFileSelect: (e) ->
    # stop bubbling
    e.preventDefault()
    e.stopPropagation()
    # take care of a drop or file select
    importFiles = e.originalEvent?.dataTransfer?.files
    unless importFiles? then importFiles = e.target.files
    # read the files to the file list
    for f in importFiles
      do (f) ->
        # create a file reader and attach a load end listener
        reader = new FileReader()
        reader.onloadend = (event) ->
          event.stopPropagation()
          event.preventDefault()
          # add to the layers collection
          if event.target.readyState is FileReader.DONE
            layers.add {
              filename: f.name
              gerber: event.target.result
            }, {
              validate: true
            }
        # read the file as text
        reader.readAsText f
    # return false to stop propagation
    false

  # laod samples from server
  loadSamples: ->
    samples = [
      'clockblock-hub-B_Cu.gbl'
      'clockblock-hub-B_Mask.gbs'
      'clockblock-hub-B_SilkS.gbo'
      'clockblock-hub-Edge_Cuts.gbr'
      'clockblock-hub-F_Cu.gtl'
      'clockblock-hub-F_Mask.gts'
      'clockblock-hub-F_Paste.gtp'
      'clockblock-hub-F_SilkS.gto'
      'clockblock-hub-NPTH.drl'
      'clockblock-hub.drl'
    ]
    for s in samples
      do (s) ->
        $.ajax {
          type: 'GET'
          url: "./#{s}"
          dataType: 'text'
          success: (data) -> layers.add { filename: s, gerber: data }
        }
}
