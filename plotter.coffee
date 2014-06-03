# plotter class for svgerber
# constructor takes in gerber file as string

class Plotter
  constructor: (gerberFile) ->
    # parse the monolithic string into an array of lines
    @gerber = gerberFile.split '\n'
    console.log "Plotter class created. Gerber array: "
    console.log @gerber
