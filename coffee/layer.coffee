# a selection of classes for building a circuit board

#require 'lib/svg.js'
#require 'aperture.coffee'

# export the Layer
root = exports ? this

# layer object (pad or trace)
class LayerObject
  # constructor takes in the tool shape, start position, parameters
  constructor: (tool, params) ->
    @parseTool(tool)
    @parseParams(params)

  parseTool: (t) ->
    @shape = t.shape
    p = t.params
    switch @shape
      when 'C'
        unless p[0]? then throw "BadCircleParamsError"
        @dia = p[0]
      when 'R'
        unless p.length > 1 then throw "BadRectParamsError"
        @size = p[0..1]

  parseParams: (p) ->
    if p < 2 then throw 'NotEnoughToolParamsError'
    @x = p[0]
    @y = p[1]


# pad class for Layer
class Pad extends LayerObject
  # parse the parameters into something useful
  parseTool: (t) ->
    p = t.params
    switch t.shape
      when 'C'
        @holeX = if p[1]? then p[1] else null
        @holeY = if p[2]? then p[2] else null
      when 'R', 'O'
        @holeX = if p[2]? then p[2] else null
        @holeY = if p[3]? then p[3] else null
    super t

  # parseParams: (p) ->
  #   super p

  getRange: ->
    [@x, @y]

  # draw to SVG
  draw: (drawing, origin, units) ->
    pad = null
    switch @shape
      when'C'
        console.log "drawing circular pad at #{@x}, #{@y}"
        pad = drawing.circle("#{@dia}#{units}")
        pad.center("#{@x-origin[0]}#{units}", "#{@y-origin[1]}#{units}")

      when 'R'
        console.log "rectangular pad at #{@x}, #{@y}"
        pad = drawing.rect("#{@size[0]}#{units}", "#{@size[1]}#{units}")
        #pad.center("#{@x-origin[0]}#{units}", "#{@y-origin[1]}#{units}")
        moveX = "#{@x-@size[0]/2 - origin[0]}#{units}"
        moveY = "#{@y-@size[1]/2 - origin[1]}#{units}"
        pad.move(moveX,moveY)
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
  # parse the tool for errors
  parseTool: (t) ->
    p = t.params
    switch t.shape
      when 'C'
        if p.length isnt 1 then throw "BadCircleTraceError"
      when 'R'
        if p.length isnt 2 then throw "BadRectTraceError"
      else
        console.log "shape #{@shape}, params length: #{p.length}"
        throw "InvalidTraceToolError"
    super t

  # parse the params for the end point
  parseParams: (p) ->
    if p.length isnt 4 then throw 'NotEnoughParamsForTraceError'
    @xEnd = p[2]
    @yEnd = p[3]
    super p

  getRange: ->
    [@x, @y, @xEnd, @yEnd]

  # draw to SVG
  draw: (drawing, origin, units) ->
    trace = null
    # if the tool shape is a circle, then we do a line with rounded caps
    if @shape is 'C'
      trace = drawing.line()
      # first param is circle dia
      trace.stroke {
        width: "#{@dia}#{units}"
        linecap: 'round'
      }
      # plot the stroke to the end
      trace.plot "#{@x-origin[0]}#{units}", "#{@y-origin[1]}#{units}", "#{@xEnd-origin[0]}#{units}", "#{@yEnd-origin[1]}#{units}"

    # if the tool shape is a rect, then we gotta get fancy
    else if @shape is 'R'
      console.log "fancy trace"

# fill class
class Fill extends LayerObject

# layer class
class root.Layer
  constructor: (@name) ->
    @layerObjects = []
    @minX = null
    @minY = null
    @maxX = null
    @maxY = null

  setUnits: (u) ->
    if u is 'IN' then @units = 'in' else if u is 'MM' then @units = 'mm'


  getSize: ->
    [@minX, @maxX, @minY, @maxY]

  # add a pad, trace, or fill(?)
  addObject: (action, tool, params) ->
    switch action
      # draw a trace
      when 'T'
        t = new Trace(tool, params)
        for m, i in t.getRange()
          if i%2 is 0
            if (not @minX?) or (m < @minX)
              @minX = m
            else if (not @maxX?) or (m > @maxX)
              @maxX = m
          else
            if (not @minY?) or (m < @minY)
              @minY = m
            else if (not @maxY?) or (m > @maxY)
              @maxY = m
        @layerObjects.push t
      # flash a pad
      when 'P'
        p = new Pad(tool, params)
        for m, i in p.getRange()
          if i%2 is 0
            if (not @minX?) or (m < @minX)
              @minX = m
            else if (not @maxX?) or (m > @maxX)
              @maxX = m
          else
            if (not @minY?) or (m < @minY)
              @minY = m
            else if (not @maxY?) or (m > @maxY)
              @maxY = m
        @layerObjects.push p
      # create a region fill
      when 'F'
        console.log "create a fill or something"
      else
        throw "#{action}_IsInvalidInputTo_Layer::addObject_Error"

  draw: (id) ->
    console.log "drawing layer origin at #{@minX}, #{@minY}"
    console.log "objects to draw: #{@layerObjects.length}"
    # create an SVG object
    svg = SVG(id).size("#{0.5+(@maxX-@minX)}#{@units}", "#{0.5+(@maxY-@minY)}#{@units}",)
    # draw a rectanle
    # rect = drawing.rect(100, 100).attr({ fill: '#f06' })
    # return the div
    #drawDiv
    # draw all the objects
    o.draw(svg, [@minX-0.25, @minY-0.25], @units) for o in @layerObjects
