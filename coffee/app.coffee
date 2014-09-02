# main svgerber site application
# jquery
#$ = require 'jquery'
# gerber to svg plotter
gerberToSvg = require 'gerber-to-svg'
# board builder
buildBoard = require './build-board'

# btoa polyfill
unless typeof window.btoa is 'function'
  window.btoa = (require 'Base64').btoa


# board colors
COLORS = {
  cu: {
    bare:    { bg: '#C87533',       txt: 'white' }
    gold:    { bg: 'goldenrod',     txt: 'white' }
    'Ni/Au': { bg: 'whitesmoke',    txt: 'black' }
    hasl:    { bg: 'silver',        txt: 'black' }
  }
  sm: {
    red:    { bg: 'darkred',    txt: 'white' }
    orange: { bg: 'darkorange', txt: 'black' }
    yellow: { bg: '#FFFF66',    txt: 'black' }
    green:  { bg: 'darkgreen',  txt: 'white' }
    blue:   { bg: 'navy',       txt: 'white' }
    purple: { bg: 'indigo',     txt: 'white' }
    black:  { bg: 'black',      txt: 'white' }
    white:  { bg: 'white',      txt: 'black' }
  }
  ss: {
    red:    { bg: 'red',    txt: 'white' }
    yellow: { bg: 'yellow', txt: 'black' }
    green:  { bg: 'green',  txt: 'white' }
    blue:   { bg: 'blue',   txt: 'white' }
    black:  { bg: 'black',  txt: 'white' }
    white:  { bg: 'white',  txt: 'black' }
  }
  built: false
  defaults: { cu: 'gold', sm: 'green', ss: 'white' }
}

# layer types
LAYERS = {
  tcu: { desc: 'top copper',        match: /\.(gtl)|(cmp)$/i }
  tsm: { desc: 'top soldermask',    match: /\.(gts)|(stc)$/i }
  tss: { desc: 'top silkscreen',    match: /\.(gto)|(plc)$/i }
  tsp: { desc: 'top solderpaste',   match: /\.(gtp)|(crc)$/i }
  bcu: { desc: 'bottom copper',     match: /\.(gbl)|(sol)$/i }
  bsm: { desc: 'bottom soldermask', match: /\.(gbs)|(sts)$/i }
  bss: { desc: 'bottom silkscreen', match: /\.(gbo)|(pls)$/i }
  bsp: { desc: 'bottom solderpaste',match: /\.(gbp)|(crs)$/i }
  icu: { desc: 'inner copper',      match: /\.(gp\d+)|(g\d+l)$/i }
  out: { desc: 'board outline',     match: /(\.(gko)|(mil)$)|edge/i }
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

# board output
boardOutput = $ '#board-output'
# board color picker buttons
boardColorMainBtn = $ 'button[name="board-color-btn"]'
boardColorContainer = $ '#board-output-color'
# color picker buttons
boardColorPickerBtn = $ '.ColorPicker--btn'

# layer output
layerOutput = $ '#layer-output'

# nav links
nav = $ '#main-nav'
navHome = $('#nav-top').children 'a.Nav--brand'
navFiles = $ '#nav-filelist'
navSvgs = $ '#nav-output, #nav-layers'
# nav buttons
navButtons = $ 'Nav--linkButton'

changeIcon = (element, newIcon) ->
  element.removeClass( (i, c) -> c.match(/octicon-\S+/g)?.join ' ')
    .addClass newIcon

matchLayer = (filename) ->
  for key, val of LAYERS
    return key if filename.match val.match

# remove layer output
removeLayerOutput = ->
  $('#board-output, #layer-output').children().not('.is-js-template').remove()
  $('#board-output-row, #layer-output-row').addClass 'is-hidden'
  # clear out the download links
  $('#download-top-btn, #download-bottom-btn').addClass('is-disabled')
    .attr 'href', '#'
  # disable the nav link
  navSvgs.addClass 'is-disabled'

# (re)start the app
restart = ->
  # reset the processed flag
  processed = false
  # clear out the internal lists
  fileList = {}
  layerList = {}
  # remove the file listings from the DOM and hide the section
  docFileList.addClass 'is-hidden'
  docFileList.children('ul').children().not('.is-js-template').remove()
  # remove the board renders
  removeLayerOutput()
  # rehide to color selector
  boardColorContainer.addClass('is-retracted').removeClass 'is-extended'
  # remove the restart icon from the home nav link and disable filelist link
  changeIcon navHome, 'octicon-jump-up'
  navFiles.addClass 'is-disabled'

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
  # show the file list and enable the nav icon
  if docFileList.hasClass 'is-hidden'
    docFileList.removeClass 'is-hidden'
    navFiles.removeClass 'is-disabled'
    # add the restart icon to the home nav link
    changeIcon navHome, 'octicon-sync'
    # scroll to the filelist
    scrollTo docFileList

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
          event.target.result = null
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
  # restart app
  restart()
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

# build the color selectors for the board output
buildColorPicker = ->
  unless COLORS.built
    # loop through copper, soldermask, and silkscreen
    for elem in [ 'cu', 'sm', 'ss' ]
      # find the copper color button template
      temp = $("#board-#{elem}-color-buttons").children('button.is-js-template')
      for c, code of COLORS[elem]
        newBtn = temp.clone().removeClass 'is-js-template'
        newBtn.css('background-color', code.bg).css 'color', code.txt
        newBtn.html c
        if c is COLORS.defaults[elem] then newBtn.prop 'disabled', true
        temp.before newBtn
    # color picker buttons
    boardColorPickerBtn = $ '.ColorPicker--btn'
    # attach event listener
    boardColorPickerBtn.on 'click', changeColor
    # set the built flag
    COLORS.built = true

# encode for download
encodeForDownload = ->
  containers = $('.BoardContainer').not('.is-js-template')
  containers.each ->
    c = $ this
    drawDiv = c.children('.LayerDrawing')
    svg = drawDiv.html()
    svg64 = "data:image/svg+xml;base64,#{btoa svg}"
    if c.attr('id') is 'board-top-render'
      btn = $('#download-top-btn')
    else if c.attr('id') is 'board-bottom-render'
      btn = $('#download-bottom-btn')
    btn.attr 'href', svg64
    btn.removeClass 'is-disabled'


changeColor = (clicked) ->
  # get the elements for board stlyes
  style = $ '.Board--style'
  # use text because svg is xml, not html (and makes safari unhappy)
  styleString = style.first().text()
  # get the element that we're changing to color
  clicked = $ clicked.target
  clickId = clicked.parent().attr 'id'
  if clickId.match /cu/
    color = COLORS.cu[clicked.html()].bg
    newStyle = ".Board--finish { color: #{color}; }"
    reStyle = /\.Board--finish {.*}/
  else if clickId.match /ss/
    color = COLORS.ss[clicked.html()].bg
    newStyle = ".Board--ss { color: #{color}; }"
    reStyle = /\.Board--ss {.*}/
  else if clickId.match /sm/
    color = COLORS.sm[clicked.html()].bg
    opacity = styleString.match(/opacity:.*;/)?[0]
    newStyle = ".Board--sm { color: #{color}; #{opacity} }"
    reStyle = /\.Board--sm {.*}/
  # clear any disables
  clicked.siblings().prop 'disabled', false
  # disabled current
  clicked.prop 'disabled', true
  # replace the style
  style.text styleString.replace reStyle, newStyle
  # encode new
  encodeForDownload()


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

  # slight delay to debounce button disable, then convert
  setTimeout () ->
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
          layer.children('h2.LayerHeading').html option.html()
          layer.find('img.LayerImage').attr 'src', svg64
          # put it in the DOM
          docLayerTemplate.before layer
    # board output
    topLayers = {}
    if layerList.tcu? then topLayers.cu = layerList.tcu
    if layerList.tsm? then topLayers.sm = layerList.tsm
    if layerList.tss? then topLayers.ss = layerList.tss
    if layerList.tsp? then topLayers.sp = layerList.tsp
    if layerList.drl? then topLayers.drill = (d for d in layerList.drl)
    if layerList.out? then topLayers.out = layerList.out
    bottomLayers = {}
    if layerList.bcu? then bottomLayers.cu = layerList.bcu
    if layerList.bsm? then bottomLayers.sm = layerList.bsm
    if layerList.bss? then bottomLayers.ss = layerList.bss
    if layerList.bsp? then bottomLayers.sp = layerList.bsp
    if layerList.drl? then bottomLayers.drill = (d for d in layerList.drl)
    if layerList.out? then bottomLayers.out = layerList.out
    # find the board template
    boardTemplate = $('#board-output').children('.is-js-template')
    # top
    if topLayers.cu?
      topBoard = buildBoard 'top', topLayers
      topContainer = boardTemplate.clone().removeClass 'is-js-template'
      topContainer.attr 'id', 'board-top-render'
      topContainer.children('h2.LayerHeading').html 'board top'
      svg = gerberToSvg topBoard
      #svg64 = "data:image/svg+xml;base64,#{btoa svg}"
      topContainer.find('img.LayerImage').replaceWith svg
      boardTemplate.before topContainer
    # bottom
    if bottomLayers.cu?
      bottomBoard = buildBoard 'bottom', bottomLayers
      bottomContainer = boardTemplate.clone().removeClass 'is-js-template'
      bottomContainer.attr 'id', 'board-bottom-render'
      bottomContainer.children('h2.LayerHeading').html 'board bottom'
      svg = gerberToSvg bottomBoard
      #svg64 = "data:image/svg+xml;base64,#{btoa svg}"
      bottomContainer.find('img.LayerImage').replaceWith svg
      boardTemplate.before bottomContainer

    # build color pickers if necessary and unhide the bourd output
    if bottomLayers.cu? or topLayers.cu?
      buildColorPicker()
      encodeForDownload()
      $('#board-output-row').removeClass 'is-hidden'

    # unhide the layer output
    $('#layer-output-row').removeClass 'is-hidden'
    # scroll to the board output
    scrollTo boardOutput, ->
      # enable the nav links
      navSvgs.removeClass 'is-disabled'
    # return false
    false
  # timeout debounce delay
  , 50

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
# slide out color drawer
boardColorMainBtn.on 'click', -> boardColorContainer.toggleClass 'is-retracted'
# color button

# navigation sugar
navHeight = nav.height()
# scroll to
scrollTo = (selector, cb) ->
  $('html, body').animate {
    scrollTop: if selector then $( selector ).offset().top-1.15*navHeight else 0
  }, 300, cb

$('a.Nav--link').not('.Nav--noScroll').on 'click', (event) ->
  event.stopPropagation()
  event.preventDefault()
  a = $ @
  p =  a.parent()
  unless p.hasClass 'disabled'
    link = a.attr('href').split('#')[1]
    if link then link = '#'+link
    # restart if the link was empty
    scrollTo link, (unless link then restart)
