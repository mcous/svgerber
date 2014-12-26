# webworker to handle converting gerber to svg
# pull in the library
gerberToSvg = require 'gerber-to-svg'

# convert to xml object function
convertGerber = (filename, gerber) ->
  # warnings array
  warnings = []
  # if it's an object, half our job is done
  if typeof gerber is 'object' then obj = gerber
  else
    # try it as a gerber first
    try
      obj = gerberToSvg gerber, { object: true, warnArr: warnings }
    catch e
      # if that errors, try it as a drill
      try
        warnings = []
        obj = gerberToSvg gerber, { 
          drill: true, object: true, warnArr: warnings
        }
      catch e2
        warnings = []
        obj = {}
  # take the xmlObject and get the string
  if obj.svg? then string = gerberToSvg obj else string = ''
  # return the message
  { filename: filename, svgObj: obj, svgString: string, warnings: warnings }

self.addEventListener 'message', (e) ->
  gerber = e.data.gerber
  filename = e.data.filename
  # post the message
  self.postMessage convertGerber filename, gerber
, false
