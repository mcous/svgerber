# check for file api support
# looks good to me
# if window.File and window.FileReader and window.FileList and window.Blob
#   alert 'file api is go'
# else
#   alert 'file api is no'

# take care of a file event
handleFileSelect = (event) ->
  importFiles = event.target.files
  output = []

  for f in importFiles
    output.push '<li><strong>', escape(f.name), '</li>'

  document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>'

document.getElementById('files').addEventListener('change', handleFileSelect, false)
