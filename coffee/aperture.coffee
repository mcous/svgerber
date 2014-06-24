# export the Aperture class
root = exports ? this

# aperture class used by the plotter and board classes
class root.Aperture
  constructor: (params) ->
    @["#{key}"] = value for key, value of params
    #@print()

  print: ->
    p = "aperture #{@code} is a #{@shape} with "
    switch @shape
      when 'C'
        p += "dia: #{@dia}"
      when 'R', 'O'
        p += "x size: #{@sizeX}, y size: #{@sizeY}"
      when 'P'
        p += "circumscribed dia: #{@dia}, points: #{@points}"
        if @rotation?
          p+= ", rotation: #{@rotation}"
      else
        p += 'macro stuff'
    if @holeX?
      unless @holeY?
        p += ", hole dia: #{@holeX}"
      else
        p += ", hole x size: #{@holeX}, hole y size #{@holeY}"
    console.log p
