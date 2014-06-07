# a selection of classes for building a circuit board

#require 'aperture.coffee'

# layer object (pad or trace)
class LayerObject
  # constructor takes in the tool shape, start position, parameters
  constructor: (@shape, @x, @y, params) ->
    @size = null
    @parseParams(params)

  parseParams: (p) ->
    switch @shape
      when 'C'
        unless p[0]? then throw "BadCircleParamsError"
        @size = p[0]
      when 'R'
        unless p.length > 1 then throw "BadRectParamsError"
        @size = p[0..1]


# pad class for Layer
class Pad extends LayerObject
  # parse the parameters into something useful
  parseParams: (p) ->
    switch @shape
      when 'C'
        @holeX = if p[1]? then p[1] else null
        @holeY = if p[2]? then p[2] else null
      when 'R', 'O'
        @holeX = if p[2]? then p[2] else null
        @holeY = if p[3]? then p[3] else null
    super p

  # draw to SVG
  draw: (drawing) ->
    pad = null
    switch @shape
      when'C'
        console.log "circular pad at #{@x}, #{@y}"
        pad = drawing.circle(@size).center(@x, @y)

      when 'R'
        console.log "rectangular pad at #{@x}, #{@y}"
        pad = drawing.rect(@size[0], @size[1]).center(@x, @y)

      when 'O'
        console.log "obround pad"
      when 'P'
        console.log "polygon pad"
      else
        console.log "unrecognized shape"

    if @holeX?
      # positve mask for the pad itself
      p = pad.clone().fill {color: '#fff'}
      # negative mask for the hole
      h = null
      # rectangle or circle
      if @holeY?
        h = drawing.rect(@holeX, @holeY)
      else
        h = drawing.circle(@holeX)
      # center the hole and fill properly
      h.center(pad.cx(), pad.cy()).fill {color: '#000'}
      # mask the hole out
      m = drawing.mask().add(p).add(h)
      pad.maskWith m

# trace class for Layer
class Trace extends LayerObject
  # parse the parameters into something useful
  parseParams: (p) ->
    switch @shape
      when 'C'
        if p.length isnt 3 then throw "BadCircleTraceError"
        @end = p[1..2]
      when 'R'
        if p.length isnt 4 then throw "BadRectTraceError"
        @end = p[2..3]
      else
        throw "InvalidTraceShapeError"
    super p

  # draw to SVG
  draw: (drawing) ->
    # if the tool shape is a circle, then we do a line with rounded caps
    if @shape is 'C'
      trace = drawing.line()
      # first param is circle dia
      trace.stroke {
        width: @size
        linecap: 'round'
      }
      # plot the stroke to the end
      trace.plot @x, @y, @end[0], @end[1]

    # if the tool shape is a rect, then we gotta get fancy
    else if @shape is 'R'
      console.log "fancy trace"


# fill class
class Fill extends LayerObject

# layer class
class Layer
  constructor: (@name) ->
    @layerObjects = []

  # add a pad, trace, or fill(?)
  addObject: (action, tool, params) ->
    switch action
      # draw a trace
      when 'T'
        t = new Trace(tool.shape, tool.params)
      # flash a pad
      when 'P'
        p = new Pad(tool.shape, tool.params)

      # create a region fill
      when 'F'
        console.log "create a fill or something"
      else
        throw "#{action}_IsInvalidInputTo_Layer::addObject_Error"

  draw: (id) ->
    # create an SVG object
    svg = SVG(id).size 500,500
    # draw a rectanle
    # rect = drawing.rect(100, 100).attr({ fill: '#f06' })
    # return the div
    #drawDiv
    # draw all the objects
    o.draw(svg) for o in @layerObjects



# export the Board class for node unit testing
if exports? then exports.Layer = Layer
