# simple file reader for svGerber

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
  p.plot()

# read a file to a div
readFileToDiv = (event) ->
  if event.target.readyState is FileReader.DONE
    textDiv = document.createElement 'p'
    textDiv.innerHTML = fileToSVG event.target.result
    document.getElementById('file-contents').insertBefore(textDiv, null)

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
