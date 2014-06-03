# plotter class for svgerber
# constructor takes in gerber file as string

# export the class for node or browser
root = exports ? this

class root.Plotter
  constructor: (gerberFile) ->
    # parse the monolithic string into an array of lines
    @gerber = gerberFile.split '\n'
    console.log "Plotter class created."
