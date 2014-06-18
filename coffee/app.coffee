# simple file reader for svGerber

# app dependencies
#require 'plotter'

# all gerbers loaded event
loaded = []
allowProcessing = ->
  button = $('#process')
  # enable the go button
  button.removeAttr 'disabled'

  # attach an event listener
  button.on 'click', (event) ->
    event.stopPropagation()
    event.preventDefault()
    # disable the button
    button.attr 'disabled', 'disabled'
    # unhide the layer outputs
    $('#individual-layer-output').removeClass 'hidden'

    # wait a few ms, then process the gerbers
    setTimeout () ->
      i = -1
      fn = () ->
        if ++i < loaded.length
          gerberToSVG loaded[i], fn
      fn()
      # for gerber in loaded
      #   do (gerber) ->
      #     gerberToSVG gerber.filename, gerber.file, gerber.name
    , 10

    false

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
  # return the value selected
  val

# read a file to a div
gerberToSVG = (gerber, callback) ->
  console.log 'drawing gerber to svg'
  filename = gerber.filename
  id = gerber.name
  gerber = gerber.file

  svg = null
  layer = null

  # plot something
  p = new Plotter gerber, id
  # get the progress bars
  drawProgress = document.getElementById "js-draw-progress-#{filename}"
  plotProgress = document.getElementById "js-plot-progress-#{filename}"

  # attach a draw progress listener to the window
  addEventListener "drawProgress_#{id}", (event) ->
    percentLoaded = event.detail.percent
    drawProgress.setAttribute 'aria-valuenow', "#{percentLoaded}"
    drawProgress.style.width = "#{percentLoaded}%"

  # attach a draw done listener to the window
  addEventListener "drawDone_#{id}", (event) ->
    # update progress bar
    drawProgress.setAttribute 'aria-valuenow', '100'
    drawProgress.style.width = '100%'
    # grab svg
    svg = event.detail.svg

    # wait briefly, then call the callback
    setTimeout () ->
      if callback? and typeof callback is 'function'
        callback()
    , 250

  # attach a plot progress listener to the window
  addEventListener "plotProgress_#{id}", (event) ->
    # get the progress
    percentLoaded = event.detail.percent
    console.log "percent plotted: #{percentLoaded}"
    # set the progress bar
    plotProgress.setAttribute 'aria-valuenow', "#{percentLoaded}"
    plotProgress.style.width = "#{percentLoaded}%"

  # attach a plot done listener to the window
  addEventListener "plotDone_#{id}", (event) ->
    # update the progress bar
    plotProgress.setAttribute 'aria-valuenow', '100'
    plotProgress.style.width = '100%'
    # draw the layer after a delay
    setTimeout () ->
      event.detail.layer.draw id
    , 250

  # plot the layer
  p.plot()

  #svg = layer.draw id
  # create a div for the drawing to live in
  # template = $ '#js-layer-container-template'
  # container = template.clone().removeClass 'js-template'

  # set the id of the draw div and the heading of the container properly
  # container.children('h4.layer-heading').text("#{filename}")
  # drawDiv = container.children 'div.layer-drawing'
  # drawDiv.attr 'id', "js-layer-drawing-#{filename}"
  # template.after container
  # # drawDiv.innerHTML = "<h3>#{filename}</h3>"
  # # drawDiv.id = "layer-#{layer.name}"
  # # drawDiv.class = 'layer-div'
  # # document.getElementById('layers').insertBefore(drawDiv, null)
  # # # draw the layer to the div
  # svg = layer.draw drawDiv.attr 'id'
  # svg64 = btoa svg.node.outerHTML
  #
  # # append the download link
  # imgsrc = "data:image/svg+xml;base64,#{svg64}"
  # drawDiv.innerHTML += "<a download='filename' href-lang='image/svg+xml' href='#{imgsrc}'>download svg</a>"

# file load progress
updatePlotProgress = (event, filename, progress) ->
  detail = event.detail
  if detail.current?
    percentLoaded = Math.round detail.current/detail.total * 100
    if percentLoaded <= 100
      progress['aria-valuenow'] = "#{percentLoaded}"
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

  # read the uploaded files to a div
  for f in importFiles
    # closure wrapping!
    do (f) ->
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
      name = setLayerSelect layerSelect, f.name

      # set the progress bar ids and values
      progress = item.find '#js-plot-progress-template'
      progress.attr 'id', "js-plot-progress-#{f.name}"
      progress.attr('aria-valuenow', '0').width '0%'
      progress = item.find '#js-draw-progress-template'
      progress.attr 'id', "js-draw-progress-#{f.name}"
      progress.attr('aria-valuenow', '0').width '0%'

      # append
      item.removeClass 'js-template'
      template.after item

      # file reader with onload event attached
      reader = new FileReader()
      reader.onloadend = (event) ->
        # add to the array of loaded files
        if event.target.readyState is FileReader.DONE
          loaded.push {filename: f.name, file: event.target.result, name: name}
          # if all files are loaded
          if loaded.length is importFiles.length
            allowProcessing()
      reader.readAsText f

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
fileSelect = document.getElementById 'file-upload-select'
fileSelect.addEventListener 'change', handleFileSelect, false
