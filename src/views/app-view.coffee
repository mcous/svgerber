# svgerber backbone app

# utilities
githubApiUrl = require '../github-api-url'

# require our other views
FilelistItemView = require './filelist-item'
LayerView = require './layer-view'
BoardView = require './board-view'
ColorPickerView = require './color-picker'
ModalView = require './modal-view'
UnsupportedView = require './unsupported-view'

# create a layers collection
LayerList = require '../collections/layers'
layers = new LayerList()
# create collection for board renders with the top and the bottom
BoardList = require '../collections/boards'
boards = new BoardList()
boards.add [
  { name: 'top', layers: layers }
  { name: 'bottom', layers: layers }
]

# create the modal
modal = new ModalView()

module.exports = Backbone.View.extend {
  el: '#svgerber-app'

  # app events
  events: {
    # file upload events
    # dropzone file drop
    'drop #dropzone': 'handleFileSelect'
    # dropzone dragover - stop browser from opening file and show copy tooltip
    'dragover #dropzone': (e) ->
      e.preventDefault()
      e.stopPropagation()
      e.originalEvent.dataTransfer.dropEffect = 'copy'
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
    @listenTo boards, 'change:svg', @addBoardRender
    # add or remove color picker if necessary
    @listenTo boards, 'change:svg', @handleColorPicker
    # listen to the layers collection for adds and removed
    # adjust nav icons accordingly
    @listenTo layers, 'add remove', @handleNavIcons
    # attach the modal view and listen for open modal events
    @$el.append modal.render().el
    @listenTo layers, 'openModal', @handleOpenModal
    @listenTo boards, 'openModal', @handleOpenModal
    



  # remove all models from the layers collection
  restart: -> layers.remove layers.models

  # add a filelist item to the filelist
  addFilelistItem: (layer) ->
    # add to the filelist if necessary
    view = new FilelistItemView { model: layer }
    $('#filelist').append view.render().el

  # add a board layer
  addBoardLayer: (layer) ->
    if layer.get('svg').length
      view = new LayerView { model: layer }
      $('#layer-output').append view.render().el

  # add a board render if needed
  addBoardRender: (board) ->
    existing = $('#board-output').find('.LayerHeading').text()
    if board.get('svg').length and not existing.match(board.get 'name')?
      view = new BoardView { model: board }
      $('#board-output').append view.render().el

  # handle an open modal event
  handleOpenModal: (render) -> modal.openModal render

  # add color picker to the page if it's not there
  handleColorPicker: (boards) ->
    # if there's no color picker
    pickerExists = $('#board-output').siblings('.ColorPicker').length
    boardsExist = $('#board-output').children().length
    if not pickerExists and boardsExist
      view = new ColorPickerView { collection: boards }
      $('#board-output').after view.render().el

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
        # add the layer to the collection
        layers.add { name: f.name }, { validate: true }
        # create a file reader and attach a load end listener
        reader = new FileReader()
        reader.onloadend = (event) ->
          event.stopPropagation()
          event.preventDefault()
          # set the gerber of the layer
          if event.target.readyState is FileReader.DONE
            (layers.findWhere { name: f.name }).set 'gerber', event.target.result
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
    @restart()
    # get the samples from the server
    for s in samples
      do (s) ->
        # add the layer to the collection
        layers.add { name: s }, { validate: true }
        # get the file contents
        $.ajax {
          type: 'GET'
          url: "./#{s}"
          dataType: 'text'
          success: (data) -> (layers.findWhere { name: s }).set 'gerber', data
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
        success: (data) ->
          layers.add { name: data.name }, { validate: true }
          (layers.findWhere { name: data.name }).set 'gerber', data.content
      }
    @hidePaste()

  # handle navigation icons
  handleNavIcons: ->
    if layers.length is 0
      $('#nav-filelist, #nav-output, #nav-layers').addClass 'is-disabled'
      @changeIcon $('.Nav--brand'), 'octicon-jump-up'
      $('#nav-top').off 'click', @restart
    else
      $('#nav-filelist, #nav-output, #nav-layers').removeClass 'is-disabled'
      @changeIcon $('.Nav--brand'), 'octicon-sync'
      $('#nav-top').on 'click', @restart

  # change icon helper
  changeIcon: (element, newIcon) ->
    element.removeClass( (i, c) -> c.match(/octicon-\S+/g)?.join ' ')
      .addClass newIcon

}
