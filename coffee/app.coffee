# main svgerber site application
# jquery
$ = require 'jquery'
# gerber to svg plotter
gerberToSvg = require 'gerber-to-svg'
# board builder
buildBoard = require './build-board.coffee'

# layer types
LAYERS = {
  tcu: { desc: 'top copper',        match: /(\.gtl)|(\.cmp)$/i }
  tsm: { desc: 'top soldermask',    match: /(\.gts)|(\.stc)$/i }
  tss: { desc: 'top silkscreen',    match: /(\.gto)|(\.plc)$/i }
  tsp: { desc: 'top solderpaste',   match: /(\.gtp)|(\.crc)$/i }
  bcu: { desc: 'bottom copper',     match: /(\.gbl)|(\.sol)$/i }
  bsm: { desc: 'bottom soldermask', match: /(\.gbs)|(\.sts)$/i }
  bss: { desc: 'bottom silkscreen', match: /(\.gbo)|(\.pls)$/i }
  bsp: { desc: 'bottom solderpaste',match: /(\.gbp)|(\.crs)$/i }
  icu: { desc: 'inner copper',      match: /\.gp\d$/i }
  out: { desc: 'board outline',     match: /(\.gko$)|edge/i }
  drw: { desc: 'gerber drawing',    match: /\.gbr$/i }
  drl: {
    desc: 'drill hits'
    match: /(\.xln$)|(\.drl$)|(\.txt$)|(\.drd$)/i
  }
}
# layers that may have multiple files
MULT_LAYERS = [ 'oth', 'icu', 'drw', 'drl' ]
# uploaded filename to jquery friendly id map
fileList = {}
# layers to process
layerList = {}
processed = false

# document elements
# the file list
docFileList = $ 'output#file-list'
docFileItemTemplate = docFileList.children('ul').children 'li.is-js-template'
docConvertBtn = $ 'button#convert-btn'
convertBtnMsg = {
  before: 'convert!'
  after: 'done!'
  error: 'error: matching layer selections'
}
# the individual layer outputs
docLayerTemplate = $('#layer-output').children('.LayerContainer.is-js-template')
# url paste buttons
docPasteBtn = $ '#url-paste-btn'
docPasteSubmitBtn = $ 'button[name="url-paste-submit-btn"]'
docPasteCancelBtn = $ 'button[name="url-paste-cancel-btn"]'
docPasteForm = $ '#url-paste-form'
docPasteText = $ '#url-paste'
# sample load button
docSampleBtn = $ '#sample-btn'

changeIcon = (element, newIcon) ->
  element.removeClass( (i, c) -> c.match(/octicon-\S+/g)?.join ' ')
    .addClass newIcon

matchLayer = (filename) ->
  for key, val of LAYERS
    return key if filename.match val.match

# remove layer output
removeLayerOutput = ->
  $('#board-output, #layer-output')
    .addClass 'is-hidden'
    .children().not('.is-js-template').remove()

# (re)start the app
restart = ->
  # reset the processed flag
  processed = false
  # clear out the internal lists
  fileList = {}
  layersToProcess = {}
  # remove the file listings from the DOM
  docFileList.children('ul').children().not('.is-js-template').remove()
  # remove the board renders
  removeLayerOutput()

# build the file list
# populate select menu in the template for list items
populateSelect = do ->
  select = docFileItemTemplate.find('select')
  for short, long of LAYERS
    select.append "<option value=\"#{short}\">#{long.desc}</option>"

validateLayerSelections = ->
  layers = []
  valid = true
  selectMenus = $('.UploadList--SelectMenu')
  selectMenus.each (index)->
    select = $ this
    list = select.parents('li.UploadList--item')
      .removeClass('is-valid is-invalid is-ignored')
    ly = select.children("option:selected").attr 'value'
    # if it's already been selected we have a problem
    if ly in layers
      valid = false
      # gather all the bad lists
      list = list.add(
        list.siblings().find("option:selected[value=#{ly}]").parents('li')
      )
      # add the invalid class and change the icon to a no-go
      list.addClass 'is-invalid'
      changeIcon list.find('.mega-octicon'), 'octicon-circle-slash'

    else
      # set icons and valid or ignore
      changeIcon list.find('.mega-octicon'), 'octicon-chevron-right'
      list.addClass (if ly is 'oth' then 'is-ignored' else 'is-valid')
      # if it's a mult layer then we don't care
      unless ly in MULT_LAYERS then layers.push ly

    # if we're checked all of them, either enable or disable the process button
    if index is selectMenus.length - 1
      if valid
        docConvertBtn.removeAttr('disabled')
        docConvertBtn.html convertBtnMsg.before
      else
        docConvertBtn.attr('disabled', 'disabled')
        docConvertBtn.html convertBtnMsg.error

# build the file list output and internal filelist object
buildFileListOutput = (filenames) ->
  for f in filenames
    # replace dots with underscores to make jquery happy
    id = 'select-' + f.replace /[\.\$]/g, '_'
    unless fileList[f]? then fileList[f] = {}
    fileList[f].id = id
    # get the short layer
    layer = matchLayer f
    # clone the list item template, change the filename, and autoselect a layer
    newItem = docFileItemTemplate.clone()
    newItem.removeClass 'is-js-template'
    newItem.attr 'id', id
    newItem.children('.UploadList--filename').html f
    select = newItem.find 'select'
    # add a change listener to validate selections
    select.on 'change', validateLayerSelections
    # auto select an option
    select.children("option[value=#{layer}]").attr('selected', 'selected')
    # insert the new item
    docFileItemTemplate.before newItem
  validateLayerSelections()

# take care of a file event
handleFileSelect = (e) ->
  e.preventDefault()
  e.stopPropagation()
  # restart the app if files have already been processed
  if processed then restart()
  # take care of a drop or file select
  importFiles = e.originalEvent?.dataTransfer?.files
  #if importFiles? then e.originalEvent.dataTransfer.files = null
  unless importFiles? then importFiles = e.target.files
  #e.target.files = null
  # build the file list
  buildFileListOutput (f.name for f in importFiles)
  # read the files to the file list
  for f in importFiles
    do (f) ->
      # create a file reader and attach a load end listener
      reader = new FileReader()
      reader.onloadend = (e) ->
        e.stopPropagation(); e.preventDefault()
        # add to the file list object
        if event.target.readyState is FileReader.DONE
          unless fileList[f.name]? then fileList[f.name] = {}
          fileList[f.name].string = event.target.result
      # read the file as text
      reader.readAsText f
  # return false to stop propagation
  false


# parse a standard github url into an github api url
apiUrl = (url) ->
  # strip off the http and split by /
  url = url.match(/github\.com\S+/)?[0].split '/'
  if url?.length
    api = 'https://api.github.com/repos'
    owner = url[1]
    repo = url[2]
    branch = url[4]
    path = url[5..].join '/'
    url = "#{api}/#{owner}/#{repo}/contents/#{path}?ref=#{branch}"
  else
   false

# get urls
processUrls = (urls) ->
  for u, i in urls
    u = apiUrl u
    if u then $.ajax {
      type: 'GET'
      url: u
      contentType: 'application/vnd.github.VERSION.raw'
      dataType: 'json'
      success: (data) ->
        fileList[data.name] = { string: atob data.content }
        buildFileListOutput [ data.name ]
        data = null
    }

# rest the paste box
resetPaste = ->
  docPasteText.val ''
  docPasteForm.addClass 'is-hidden'
  # return false
  false

# take care of urls pasted in
handlePaste = ->
  urls = docPasteText.val().split '\n'
  resetPaste()
  processUrls urls
  false

# load samples from server
loadSamples = ->
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
        success: (data) ->
          fileList[s] = { string: data }
          buildFileListOutput [ s ]
          data = null
      }

# convert the layers to svgs
convertLayers = ->
  # set the processed flag
  processed = true
  # remove any existing layers
  removeLayerOutput()
  # reset the paste area for safety
  resetPaste()
  # disable the button
  docConvertBtn.attr 'disabled', 'disabled'
  # for files in filelist
  for filename, val of fileList
    # get the layer type
    select = $("li.UploadList--item##{val.id}").find('select')
    option = select.children('option:selected')
    type = option.attr 'value'
    unless type is 'oth'
      # CONVERT THE MOTHERFLIPPING GERBER
      success = true
      try
        svg = gerberToSvg val.string, { object: true, drill: type is 'drl' }
      catch e
        console.warn "error with #{filename}:"
        console.warn e.message
        success = false
      if success
        if type in MULT_LAYERS
          unless layerList[type]? then layerList[type] = []
          layerList[type].push svg
        else
          layerList[type] = svg
        # CONVERT THE MOTHERFLIPPING SVG TO BINARY64
        svg64 = "data:image/svg+xml;base64,#{btoa gerberToSvg svg}"
        # set the image
        layer = docLayerTemplate.clone().removeClass 'is-js-template'
        layer.find('img.LayerImage').attr 'src', svg64
        # put it in the DOM
        docLayerTemplate.before layer

  # board output
  topLayers = {}
  if layerList.tcu? then topLayers.cu = layerList.tcu
  if layerList.tsm? then topLayers.sm = layerList.tsm
  if layerList.tss? then topLayers.ss = layerList.tss
  if layerList.tsp? then topLayers.sp = layerList.tsp
  if layerList.drl? then topLayers.drill = layerList.drl
  if layerList.out? then topLayers.edge = layerList.out
  bottomLayers = {}
  if layerList.bcu? then bottomLayers.cu = layerList.bcu
  if layerList.bsm? then bottomLayers.sm = layerList.bsm
  if layerList.bss? then bottomLayers.ss = layerList.bss
  if layerList.bsp? then bottomLayers.sp = layerList.bsp
  if layerList.drl? then bottomLayers.drill = layerList.drl
  if layerList.out? then bottomLayers.edge = layerList.out

  # find the board template
  boardTemplate = $('#board-output').children('.is-js-template')
  # top
  if topLayers.cu? and topLayers.edge?
    topBoard = buildBoard 'top', topLayers
    topContainer = boardTemplate.clone().removeClass 'is-js-template'
    svg64 = "data:image/svg+xml;base64,#{btoa gerberToSvg topBoard}"
    topContainer.find('img.LayerImage').attr 'src', svg64
    boardTemplate.before topContainer
  # bottom
  if bottomLayers.cu? and bottomLayers.edge?
    bottomBoard = buildBoard 'bottom', bottomLayers
    bottomContainer = boardTemplate.clone().removeClass 'is-js-template'
    svg64 = "data:image/svg+xml;base64,#{btoa gerberToSvg bottomBoard}"
    bottomContainer.find('img.LayerImage').attr 'src', svg64
    boardTemplate.before bottomContainer


  # unhide the output
  $('#board-output, #layer-output').removeClass 'is-hidden'
  # return false
  false


# attach event listeners to get everything going
# file drop and select
dz = $ '#dropzone'
dz.on 'dragenter', (e) -> e.preventDefault(); e.stopPropagation()
dz.on 'dragover', (e) ->
  e.preventDefault(); e.stopPropagation()
  e.originalEvent.dataTransfer.dropEffect = 'copy'
dz.on 'drop', handleFileSelect
fs = $ '#upload-select'
fs.on 'change', handleFileSelect
# convert button
docConvertBtn.on 'click', convertLayers
# url paste buttons
docPasteBtn.on 'click', -> docPasteForm.removeClass 'is-hidden'
docPasteCancelBtn.on 'click', resetPaste
docPasteSubmitBtn.on 'click', handlePaste
# load samples button
docSampleBtn.on 'click', loadSamples
# # (re)start the app
# restart = ->
#   console.log "restarting svgerber"
#
#   # delete all file listings except the template
#   $('#filelist').children().not('#js-upload-template').remove()
#   # hide the file list
#   $('#upload-list').addClass 'hidden'
#
#   # set the nav bar
#   $('a.nav-link').parent().removeClass('active').addClass 'disabled'
#   $('#nav-upload').removeClass('disabled').addClass 'active'
#
#   # hide the layer output and delete all svgs in the layer output
#   layerOutput = $('#individual-layer-output')
#   layerOutput.find('div.layer-drawing').data 'full', false
#   layerOutput.find('svg').remove()
#   layerOutput.find('.btn-download').addClass 'disabled'
#   layerOutput.find('a.layer-link').attr 'href', '#'
#   layerOutput.addClass('hidden')
#
# allowProcessing = (loaded) ->
#   # BUTTON!
#   button = $('#process').text 'svg!'
#
#   # attach an event listener
#   button.on 'click', (event) ->
#     event.stopPropagation()
#     event.preventDefault()
#     # remove the event listener
#     button.off 'click'
#     # disable the button
#     button.attr 'disabled', 'disabled'
#     button.text 'converting'
#
#     output = $('#individual-layer-output')
#     # unhide the layer outputs (but keep them invisible)
#     output.removeClass('hidden').css 'visibility', 'hidden'
#
#     # then process the gerbers recursively
#     count = -1
#     process = ->
#       if count < loaded.length then count++
#
#     i = -1
#     fn = () ->
#       i++
#       if i < loaded.length
#         console.log "i is #{i} and length is #{loaded.length}"
#         convertGerber loaded[i], fn
#       else
#         # when done, show the renders
#         output.css 'visibility', 'visible'
#         button.text 'done!'
#         # update the nav
#         $('#nav-svgs').removeClass 'disabled'
#         # go to the layers
#         $('html, body').animate {
#           scrollTop: $('#individual-layer-output').offset().top - $('#top-nav').height() - 10
#         }, 250
#     setTimeout fn, 50
#
#     # return false
#     false
#
#   # update the nav
#   $('#nav-layers').removeClass 'disabled'
#
#   # go to the go button
#   button.removeAttr 'disabled'
#   $('html, body').animate {
#     scrollTop: $('#upload-list').offset().top - $('#top-nav').height() - 10
#   }, 250
#
#
# # parse a filename for a likely layer select
# setLayerSelect = (select, filename) ->
#   # default is other
#   val = 'oth'
#   # top copper
#   if filename.match /(\.gtl)|(\.cmp)$/i
#     val = 'fcu'
#   # top soldermask
#   else if filename.match /(\.gts)|(\.stc)$/i
#     val = 'fsm'
#   # top silkscreen
#   else if filename.match /(\.gto)|(\.plc)$/i
#     val = 'fss'
#   # bottom copper
#   else if filename.match /(\.gbl)|(\.sol)$/i
#     val = 'bcu'
#   # bottom soldermask
#   else if filename.match /(\.gbs)|(\.sts)$/i
#     val = 'bsm'
#   # bottom silkscreen
#   else if filename.match /(\.gbo)|(\.pls)$/i
#     val = 'bss'
#   # board outline
#   else if filename.match /(\.gko$)|edge/i
#     val = 'out'
#   # drill hits
#   else if filename.match /(\.xln$)|(\.drl$)|(\.txt$)|(\.drd$)/
#     val = 'drl'
#
#   # set the selected attribute
#   option = select.children("[value='#{val}']").attr 'selected','selected'
#   # return the value selected
#   val
#
# # read a file to a div
# convertGerber = (gerber, callback) ->
#   console.log 'drawing gerber to svg'
#
#   filename = gerber.filename
#   select = $(document.getElementById "js-layer-select-#{filename}")
#   id = select.find(":selected").attr 'value'
#
#   # we're done if it's an other file
#   if id is 'oth' then callback?(); return
#
#   gerber = gerber.file
#   svg = null
#   layer = null
#
#   # add the drawing icon
#   icon = $(document.getElementById "js-upload-#{filename}")
#     .children '.mega-octicon'
#   icon.removeClass 'octicon-chevron-right'
#   icon.addClass 'octicon-pencil'
#   # plot the thing ()
#   layerDiv = $ "##{id}"
#   console.log "inserting svg into #{id}"
#   success = true
#   try
#     # try to grab the svg
#     svg = gerber2svg gerber, { drill: (id is 'drl') }
#   catch e
#     success = false
#     svg = """
#       <p class="error-message"> Unable to process #{filename} </p>
#       <p class="error-message"> #{e.message} </p>
#     """
#
#   # encode the svg for download if success
#   if success
#     svg64 = "data:image/svg+xml;base64,#{btoa svg}"
#     downloadBtn = layerDiv.siblings('.btn-download').removeClass 'disabled'
#     downloadBtn.children('a.layer-link').attr('href', svg64)
#
#   # change the progress bar icon
#   # remove drawing icon
#   icon.removeClass 'octicon-pencil'
#   if success then icon.addClass 'octicon-check' else icon.addClass 'octicon-x'
#
#   # put svg or error message in the div
#   layerDiv.html svg
#
#   # call the callback
#   if callback? and typeof callback is 'function' then callback()
#
#
# # take care of a file event
# handleFileSelect = (event) ->
#   # stop default actions
#   event.stopPropagation()
#   event.preventDefault()
#
#   # restart the app
#   restart()
#
#   # arrays for the uploaded files
#   importFiles = null
#   if event.dataTransfer?
#     importFiles = event.dataTransfer.files
#     event.dataTransfer.files = null
#   else
#     importFiles = event.target.files
#     event.target.files = null
#
#   # unhide the output container
#   $('#upload-list').removeClass 'hidden'
#
#   # processed files
#   loaded = []
#
#   # read the uploaded files to a div
#   for f in importFiles
#     # closure wrapping!
#     do (f) ->
#       # get the import file template list item
#       template = $ '#js-upload-template'
#       item = template.clone().attr('id', "js-upload-#{f.name}")
#
#       # set the filename
#       name = item.find '.filename-text'
#       name.text("#{f.name}")
#
#       # set the layer select id
#       layerSelect = item.find '.layer-type-select'
#       layerSelect.attr('id', "js-layer-select-#{f.name}")
#
#       # get a likely layer type
#       name = setLayerSelect layerSelect, f.name
#
#       # append
#       item.removeClass 'js-template'
#       template.after item
#
#       # file reader with onload event attached
#       reader = new FileReader()
#       reader.onloadend = (event) ->
#         event.stopPropagation()
#         event.preventDefault()
#         # add to the array of loaded files
#         if event.target.readyState is FileReader.DONE
#           console.log "pushing #{f.name} to loaded queue"
#           loaded.push {filename: f.name, file: event.target.result, name: name}
#           # if all files are loaded
#           if loaded.length is importFiles.length
#             console.log "allowing processing of #{f.name}"
#             allowProcessing loaded
#       console.log "reading as text"
#       reader.readAsText f
#
# # drag and drop file upload
# handleDragOver = (event) ->
#   event.stopPropagation()
#   event.preventDefault()
#   # explicitly say that this is a copy
#   event.dataTransfer.dropEffect = 'copy'
#
# # attach the event listener to the dropzone and the file select
# dropZone = document.getElementById 'dropzone'
# dropZone.addEventListener 'dragover', handleDragOver, false
# dropZone.addEventListener 'drop', handleFileSelect, false
# fileSelect = document.getElementById 'file-upload-select'
# fileSelect.addEventListener 'change', handleFileSelect, false
#
# # also attach event listeners on the navlinks to scroll
# navLinks = $ 'a.nav-link'
# $('a.nav-link').on 'click', (event) ->
#   event.stopPropagation()
#   event.preventDefault()
#   a = $ this
#   p = a.parent()
#   unless p.hasClass 'disabled'
#     link = a.attr('href').split('#')[1]
#     # scroll to the appropriate section
#     $('html, body').animate {
#       scrollTop: $("##{link}").offset().top - $('#top-nav').height() - 10
#     }, 250
#
# # event listener on main title to restart the app and scroll to the top
# $('#title').on 'click', (event) ->
#   event.stopPropagation()
#   event.preventDefault()
#   a = $(this).children('a')
#   # restart the app
#   restart()
#   # scroll to top
#   $('html, body').animate {
#     scrollTop: 0
#   }, 250
#
# # attach an event listener on the window scroll event to set active
# w = $ window
# w.scroll () ->
#   # find the middle of the window
#   s = w.scrollTop() + w.height()/2
#
#   # by default, assume upload is active
#   unless (li = $('#nav-upload')).hasClass 'active'
#     li.siblings().removeClass 'active'
#     li.addClass 'active'
#
#   # check if we're in layer output territory
#   if s >= $('#upload-list').offset().top - $('#top-nav').height() - 10
#     unless (li = $('#nav-layers')).hasClass 'disabled' or li.hasClass 'active'
#       console.log "#nav-layers is not disabled"
#       li.siblings().removeClass 'active'
#       li.addClass 'active'
#
#   # finally check if we're in svg territory
#   if s >= $('#individual-layer-output').offset().top - $('#top-nav').height() - 10
#     unless (li = $('#nav-svgs')).hasClass 'disabled' or li.hasClass 'active'
#       console.log "#nav-svgs is not disabled"
#       li.siblings().removeClass 'active'
#       li.addClass 'active'
