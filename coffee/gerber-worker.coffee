# webworker to handle converting gerber to svg
# pull in the library
gerberToSvg = require 'gerber-to-svg'

# convert to xml object function
convertGerberToObj = (filename, gerberString) ->
  # try it as a gerber first
  obj = {}
  try
    obj = gerberToSvg gerberString, { object: true }
  catch e
    # if that errors, try it as a drill
    try
      obj = gerberToSvg gerberString, { drill: true, object: true}
    catch e2
      #if that errors, too, return the original error message
      throw new Error {
        filename: filename, error: "#{e.message} or #{e2.message}"
      }
  # return the message
  { filename: filename, xmlObj: obj }

# convert xml object to svg string
convertObjToSvg = (xmlObj) ->
  message = ''
  try
    message = gerberToSvg xmlObj
  catch e
    throw new Error "obj to svg error: #{e.message}"
  # return the message
  message

self.addEventListener 'message', (e) ->
  data = e.data.gerber
  filename = e.data.filename
  # if the message data is a string, treat it as a gerber string
  if typeof data is 'string' then message = convertGerberToObj filename, data
  else if typeof data is 'object' then message = convertObjToSvg filename, data
  else throw new Error 'invalid data input'
  # post the message
  self.postMessage message
, false
