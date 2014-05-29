# check for file api support
# looks good to me
# if window.File and window.FileReader and window.FileList and window.Blob
#   alert 'file api is go'
# else
#   alert 'file api is no'

# read a file to a div
readFile = (event) ->
  if event.target.readyState == FileReader.DONE
    textFile = event.target
    textDiv = document.createElement 'p'
    textDiv.innerHTML = textFile.result
    document.getElementById('file-contents').insertBefore(textDiv, null)

# take care of a file event
handleFileSelect = (event) ->
  # arrays for the uploaded files
  importFiles = event.target.files
  output = []

  # add some html to the output
  for f in importFiles
    output.push '<li><strong>', escape(f.name), '</li>'
    #reader.readAsText(f)

  # append the file names to the HTML
  document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>'

  for fi in importFiles
    # file reader with onload event attached
    reader = new FileReader()
    reader.addEventListener('loadend', readFile, false)
    reader.readAsText(fi)

# attach the event listener
document.getElementById('files').addEventListener('change', handleFileSelect, false)
