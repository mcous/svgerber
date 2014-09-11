# webworker to handle converting gerber to svg
# pull in the library
gerberToSvg = require 'gerber-to-svg'

# convert to xml object function
convertGerberToObj = (gerberString) ->
  # try it as a gerber first
  message = {}
  try
    message = gerberToSvg gerberString, { object: true }
  catch e
    # if that errors, try it as a drill
    try
      message = gerberToSvg gerberString, { drill: true, object: true}
    catch e2
      # if that errors, too, return the original error message
      throw new Error "gerber error: #{e.message}, drill error: #{e2.message}"
  # return the message
  message

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
  data = e.data
  # if the message data is a string, treat it as a gerber string
  if typeof data is 'string' then message = convertGerberToObj data
  else if typeof data is 'object' then message = convertObjToSvg data
  else throw new Error 'invalid data input'
  # post the message
  self.postMessage message
, false
