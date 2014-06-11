# export the Aperture class
root = exports ? this

# aperture class used by the plotter and board classes
class root.Aperture
  constructor: (@code, @shape, @params) ->
    @print()

  print: ->
    p = "aperture #{@code} is a #{@shape} with "
    switch @shape
      when 'C'
        p += "dia: #{@params.dia}"
      when 'R', 'O'
        p += "x size: #{@params.sizeX}, y size: #{@params.sizeY}"
      when 'P'
        p += 'polygon stuff'
      else
        p += 'macro stuff'
    if @params.holeX?
      unless @params.holeY?
        p += ", hole dia: #{@params.holeX}"
      else
        p += ", hole x size: #{@params.holeX}, hole y size #{@params.holeY}"
    console.log p
