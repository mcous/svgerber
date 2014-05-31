# simple file reader for svGerber

# check for file api support
# looks good to me
# if window.File and window.FileReader and window.FileList and window.Blob
#   alert 'file api is go'
# else
#   alert 'file api is no'

# convert a file to an svg
fileToSVG = (file) ->
  lines = file.split "\n"
  line = 0

  while lines[line].match(/^G04.*$/)
    line++

  # CONSOLE LOG
  console.log(lines[0])
  console.log(lines[line])
  # /CONSOLE LOG
  
  # check if is a gerber
  gerberMatch = /// ^  # start of regex, line, and file scec
    %FS                # looking for file specification
    [L,T,D]            # then, an Leading Zeros Omitted, Trailing, or Decimal
    [A,I]              # Absolute or Incremental
    (N\d+)?            # optional sequence number
    (G\d+)?            # optional preparatory function code
    X[0-5]{2}        # x data format
    Y[0-5]{2}       # y data format
    (D\d+)?            # optional draft code
    (M\d+)?            # optional misc code
    \*%$               # end of file spec and line
  ///                  # end of regex

  if lines[line].match(gerberMatch) then "it's a gerber" else "it's not a gerber"



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
