# svgerber backbone app

# utilities
githubApiUrl = require '../github-api-url'

# require our other views
FilelistItemView = require './filelist-item.coffee'
BoardLayerView = require './board-layer.coffee'
BoardRenderView = require './board-render.coffee'

# create a layers collection
LayerList = require '../collections/layers'
layers = new LayerList()
# create collection for board renders with the top and the bottom
BoardList = require '../collections/boards'
boards = new BoardList()
boards.add [
  { type: 'top', layers: layers }
  { type: 'bottom', layers: layers }
]

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
    # url paste buttons
    'click #url-paste-btn': 'showPaste'
    'click #url-submit-btn': 'processUrls'
    'click #url-cancel-btn': 'hidePaste'
  }

  initialize: ->
    # log so I don't go insane
    console.log 'svgerber app started'
    # listen to the layers collection for additions
    @listenTo layers, 'add', @addFilelistItem
    # listen to the layers collection for rendered layers
    @listenTo layers, 'processEnd', @addBoardLayer
    # create renders for the top and bottom boards
    @listenTo boards, 'render', @addBoardRender

  # add a filelist item to the filelist
  addFilelistItem: (layer) ->
    # add to the filelist
    view = new FilelistItemView { model: layer }
    $('#filelist').append view.render().el

  # add a board layer
  addBoardLayer: (layer) ->
    if layer.get('svgString').length
      console.log layer.get 'filename'
      console.log layer.get 'svgObj'
      view = new BoardLayerView { model: layer }
      $('#layer-output').append view.render().el

  # add a board render if needed
  addBoardRender: (board) ->
    existing = $('#board-output').find('.LayerHeading').text()
    if board.get('svg').length and not existing.match(board.get 'type')?
      view = new BoardRenderView { model: board }
      $('#board-output').append view.render().el

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
    # remove all models from the layers collection
    layers.remove layers.models
    for s in samples
      do (s) ->
        $.ajax {
          type: 'GET'
          url: "./#{s}"
          dataType: 'text'
          success: (data) -> layers.add { filename: s, gerber: data }
        }

  # show and hide the url paste area
  showPaste: ->
    $('#url-paste-form').removeClass 'is-hidden'
  hidePaste: ->
    $('#url-paste').val ''
    $('#url-paste-form').addClass 'is-hidden'

  # get urls
  processUrls: ->
    urls = $('#url-paste').val().split '\n'
    for u in urls
      u = githubApiUrl u
      if u then $.ajax {
        type: 'GET'
        url: u
        contentType: 'application/vnd.github.VERSION.raw'
        dataType: 'json'
        success: (data) -> layers.add {
          filename: data.name
          gerber: atob data.content
        }
      }
    @hidePaste()
}
