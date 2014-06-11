# simple file reader for svGerber

# app dependencies
#require 'plotter'

# convert a file to an svg
fileToSVG = (file) ->
  # lines = file.split "\n"
  # lines = getGerberFormat lines
  # lines = getGerberUnits lines
  #
  # lines = getGerberApertures lines
  #
  # console.log lines
  # console.log aps
  console.log 'converting to svg'
  p = new Plotter(file)

  # plot and return the layer that was plotted
  layer = p.plot()

# read a file to a div
readFileToDiv = (event) ->
  if event.target.readyState is FileReader.DONE
    # textDiv = document.createElement 'p'
    # textDiv.innerHTML = fileToSVG event.target.result

    # plot something
    layer = fileToSVG event.target.result

    # # make a new layer to draw on
    # layer = new Layer 'testlayer'
    # # make a pad and add it to the layer
    # pad = new Pad 'C', '1in', '1in', ['0.5in']
    # trace = new Trace 'C', '0.01in', '1in', ['0.005in', '3in', '1in']
    # layer.layerObjects.push pad
    # layer.layerObjects.push trace
    #
    # create a div for the drawing to live in
    drawDiv = document.createElement('div')
    drawDiv.id = "layer-#{layer.name}"
    drawDiv.class = 'layer-div'

    document.getElementById('layers').insertBefore(drawDiv, null)

    layer.draw(drawDiv.id)



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
    # file reader with onload event attached
    reader = new FileReader()
    reader.addEventListener('loadend', readFileToDiv, false)
    reader.readAsText(f)

# attach the event listener
document.getElementById('files').addEventListener('change', handleFileSelect, false)
