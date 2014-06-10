# export the Aperture class
root = exports ? this

# aperture class used by the plotter and board classes
class root.Aperture
  constructor: (@code, @shape, @params) ->
    console.log "Aperture " + @code + " was created and is a " + @shape
