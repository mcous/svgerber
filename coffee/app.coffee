# simple file reader for svGerber

# app dependencies
#require 'plotter'

# convert a file to an svg
fileToSVG = (file, filename) ->
  console.log 'converting to svg'
  p = new Plotter(file, filename[-3..])

  # plot and return the layer that was plotted
  layer = p.plot()

# read a file to a div
readFileToDiv = (event, filename) ->
  if event.target.readyState is FileReader.DONE

    # plot something
    layer = fileToSVG event.target.result, filename

    # create a div for the drawing to live in
    drawDiv = document.createElement 'div'
    drawDiv.innerHTML = "<h3>#{filename}</h3>"
    drawDiv.id = "layer-#{layer.name}"
    drawDiv.class = 'layer-div'
    document.getElementById('layers').insertBefore(drawDiv, null)
    # draw the layer to the div
    svg = layer.draw drawDiv.id
    svg64 = btoa svg.node.outerHTML

    # append the download link
    imgsrc = "data:image/svg+xml;base64,#{svg64}"
    drawDiv.innerHTML += "<a download='filename' href-lang='image/svg+xml' href='#{imgsrc}'>download svg</a>"

# take care of a file event
handleFileSelect = (event) ->
  # arrays for the uploaded files
  importFiles = event.target.files
  output = []

  # add some html to the output
  for f in importFiles
    output.push '<li><strong>', escape(f.name), '</li>'

  # append the file names to the HTML
  document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>'

  # read the uploaded files to a div
  for f in importFiles
    do (f) ->
      # file reader with onload event attached
      reader = new FileReader()
      reader.onloadend = (event) ->
        readFileToDiv event, f.name
      reader.readAsText(f)

# attach the event listener
document.getElementById('files').addEventListener('change', handleFileSelect, false)
