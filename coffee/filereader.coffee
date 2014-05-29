# check for file api support
# looks good to me
# if window.File and window.FileReader and window.FileList and window.Blob
#   alert 'file api is go'
# else
#   alert 'file api is no'

# read a file to a div
readFileToDiv = (event) ->
  if event.target.readyState == FileReader.DONE
    textDiv = document.createElement 'p'
    textDiv.innerHTML = event.target.result
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
