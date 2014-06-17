# simple file reader for svGerber

# app dependencies
#require 'plotter'

# parse a filename for a likely layer select
setLayerSelect = (select, filename) ->
  # default is other
  val = 'oth'
  # top copper
  if filename.match /.gtl$/i
    val = 'fcu'
  # top soldermask
  else if filename.match /.gts$/i
    val = 'fsm'
  # top silkscreen
  else if filename.match /.gto$/i
    val = 'fss'
  # bottom copper
  else if filename.match /.gbl$/i
    val = 'bcu'
  # bottom soldermaks
  else if filename.match /.gbs$/i
    val = 'bsm'
  # bottom silkscreen
  else if filename.match /.gbo$/i
    val = 'bss'
  # board outline
  else if filename.match /(.gko$)|edge/i
    val = 'out'

  # set the selected attribute
  option = select.children("[value='#{val}']").attr 'selected',''

# convert a file to an svg
fileToSVG = (file, filename) ->
  console.log 'converting to svg'
  p = new Plotter(file, filename[-3..])

  # plot and return the layer that was plotted
  layer = p.plot()

# read a file to a div
readFileToDiv = (event, filename) ->
  console.log "drawing to div"
  # if event.target.readyState is FileReader.DONE
  #
  #   # plot something
  #   layer = fileToSVG event.target.result, filename
  #
  #   # create a div for the drawing to live in
  #   drawDiv = document.createElement 'div'
  #   drawDiv.innerHTML = "<h3>#{filename}</h3>"
  #   drawDiv.id = "layer-#{layer.name}"
  #   drawDiv.class = 'layer-div'
  #   document.getElementById('layers').insertBefore(drawDiv, null)
  #   # draw the layer to the div
  #   svg = layer.draw drawDiv.id
  #   svg64 = btoa svg.node.outerHTML
  #
  #   # append the download link
  #   imgsrc = "data:image/svg+xml;base64,#{svg64}"
  #   drawDiv.innerHTML += "<a download='filename' href-lang='image/svg+xml' href='#{imgsrc}'>download svg</a>"

# file load progress
updateProgress = (event, file) ->
  if event.lengthComputable
    percentLoaded = Math.round event.loaded/event.total * 100
    console.log "update progress for #{file}: #{percentLoaded}%"
    if percentLoaded <= 100
      progress = document.getElementById "js-progress-#{file}"
      progress.aria-valuenow = "#{percentLoaded}"
      progress.style.width = "#{percentLoaded}%"

# take care of a file event
handleFileSelect = (event) ->
  # stop default actions
  event.stopPropagation()
  event.preventDefault()

  # arrays for the uploaded files
  importFiles = null
  if event.dataTransfer? then importFiles = event.dataTransfer.files
  else importFiles = event.target.files

  # unhide the output container
  $('#upload-output').removeClass 'hidden'

  # add some html to the output
  for f in importFiles
    # get the import file template
    template = $ '#file-upload-template'
    item = template.clone().attr('id', "js-upload-#{f.name}")

    # set the filename
    name = item.find '.filename'
    name.text("#{f.name}")

    # set the layer select id
    layerSelect = item.find '.layer-type-select'
    layerSelect.attr('id', "js-layer-select-#{f.name}")

    # get a likely layer type
    setLayerSelect layerSelect, f.name

    # set the progress bar id and values
    progress = item.find '.progress-bar'
    progress.attr('id', "js-progress-#{f.name}")
    progress.attr('aria-valuenow', '0').width('0%')

    # append
    item.removeClass 'js-template'
    template.after item

  # read the uploaded files to a div
  for f in importFiles
    do (f) ->
      # file reader with onload event attached
      reader = new FileReader()
      reader.onloadend = (event) ->
        readFileToDiv event, f.name
      reader.readAsText(f)

# drag and drop file upload
handleDragOver = (event) ->
  event.stopPropagation()
  event.preventDefault()
  # explicitly say that this is a copy
  event.dataTransfer.dropEffect = 'copy'

# attach the event listener to the dropzone and the file select
dropZone = document.getElementById 'dropzone'
dropZone.addEventListener 'dragover', handleDragOver, false
dropZone.addEventListener 'drop', handleFileSelect, false
fileSelect = document.getElementById 'fileselect'
fileSelect.addEventListener 'change', handleFileSelect, false
