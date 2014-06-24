# simple file reader for svGerber

# app dependencies
#require 'plotter'

# (re)start the app
restart = ->
  # delete all file listings except the template
  $('#filelist').children().not('#js-upload-template').remove()

  # hide the layer output and delete all svgs in the layer output
  layerOutput = $('#individual-layer-output')
  layerOutput.find('div.layer-drawing').data 'full', false
  layerOutput.find('svg').remove()
  layerOutput.find('a.layer-link').attr 'href', '#'
  layerOutput.addClass('hidden')


allowProcessing = (loaded) ->
  # BUTTON!
  button = $('#process').text 'svGo!'

  # attach an event listener
  button.on 'click', (event) ->
    event.stopPropagation()
    event.preventDefault()
    # remove the event listener
    button.off 'click'
    # disable the button
    button.attr 'disabled', 'disabled'
    button.text 'svGoing!'

    output = $('#individual-layer-output')
    # unhide the layer outputs (but keep them invisible)
    output.removeClass('hidden').css 'visibility', 'hidden'

    # then process the gerbers recursively
    # i = -1
    # fn = () ->
    #   console.log 'fn was called. incrementing i'
    #   i++
    #   if i < loaded.length
    #     console.log "i is #{i} and length is #{loaded.length}"
    #     gerberToSVG loaded[i], fn
    #   else
    #     # when done, show the renders
    #     output.css 'visibility', 'visible'
    #     button.text 'svGone!'
    #     # go to the layers
    #     $('html, body').animate {
    #       scrollTop: $('#individual-layer-output').offset().top
    #     }, 500
    # fn()

    # # process the gerbers
    done = []
    for gerber in loaded
      do (gerber) ->
        if gerber.name not in done
          gerberToSVG gerber, () ->
            done.push gerber.name
            if done.length is loaded.length
              # when done, show the renders
              output.css('visibility', 'visible')
              button.text 'svGone!'
              # go to the layers
              $('html, body').animate {
                scrollTop: $('#individual-layer-output').offset().top
              }, 500

    # return false
    false

  # go to the go button
  button.removeAttr 'disabled'
  $('html, body').animate {
    scrollTop: button.offset().top
  }, 250


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

  # progress tracking
  done = 0
  # update interval
  interval = 100

  # attach a transition end listener to the CSS3 progress animation
  plotProgress.addEventListener 'transitionend', (event) ->
    event.stopPropagation()
    event.preventDefault()
    if done < 100
      console.log "plotting to #{done + interval}"
      done = p.plotToPercent done + interval
      console.log "got to #{done}"
      plotProgress.setAttribute 'aria-valuenow', "#{done}"
      plotProgress.style.width = "#{done}%"
    else
      # we're done
      plotProgress.removeEventListener 'transitionend'
      p.layer.drawNext()
      # enocode svg for download
      svg64 = "data:image/svg+xml;base64,#{btoa p.layer.svg.node.outerHTML}"
      $("##{id}").siblings('a.layer-link').attr 'href', svg64

      # call the callback
      if callback? and typeof callback is 'function' then callback()


  # plot and draw the layer
  console.log "plotting to #{done + interval}"
  done = p.plotToPercent done + interval
  console.log "got to #{done}"
  plotProgress.setAttribute 'aria-valuenow', "#{done}"
  plotProgress.style.width = "#{done}%"



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

  # restart the app
  restart()

  # arrays for the uploaded files
  importFiles = null
  if event.dataTransfer?
    importFiles = event.dataTransfer.files
    event.dataTransfer.files = null
  else
    importFiles = event.target.files
    event.target.files = null

  # unhide the output container
  $('#upload-output').removeClass 'hidden'

  # processed files
  loaded = []

  # read the uploaded files to a div
  for f in importFiles
    console.log "#{f.name} is in importFiles. length is #{importFiles.length}"
    # closure wrapping!
    do (f) ->
      # get the import file template list item
      template = $ '#js-upload-template'
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
        event.stopPropagation()
        event.preventDefault()
        # add to the array of loaded files
        if event.target.readyState is FileReader.DONE
          console.log "pushing #{f.name} to loaded queue"
          loaded.push {filename: f.name, file: event.target.result, name: name}
          # if all files are loaded
          if loaded.length is importFiles.length
            console.log "allowing processing of #{f.name}"
            allowProcessing loaded
      console.log "reading as text"
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
