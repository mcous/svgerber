# main svgerber site application

# # gerber to svg plotter
# gerber2svg = require 'gerber-to-svg'
#
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
