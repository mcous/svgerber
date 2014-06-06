# aperture class used by the plotter and board classes
class Aperture
  constructor: (@code, @shape, @params) ->
    console.log "Aperture " + @code + " was created and is a " + @shape

# export the Aperture class for node unit testing
if exports? then exports.Aperture = Aperture
