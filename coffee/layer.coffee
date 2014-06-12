# a selection of classes for building a circuit board

#require 'lib/svg.js'
#require 'aperture.coffee'

# export the Layer
root = exports ? this

# layer object (pad or trace)
class LayerObject
  # constructor takes in the tool shape, start position, parameters
  constructor: (@tool, @x, @y, @coord = null) ->
    @print()

# pad class for Layer
class Pad extends LayerObject
  print: ->
    console.log "#{@tool.shape} pad created at #{@x}, #{@y}"

  getRange: ->
    [@x, @y]

  # draw to SVG
  # parameters are the drawing object,
  # an origin object with keys x and y
  # a canvas object with keys width, height, and margin
  # the units for the drawing
  draw: (drawing, origin, canvas, units) ->
    pad = null

    # adjust for origin and margin in x
    x = @x - origin.x + canvas.margin
    # add the units
    #x = "#{x}#{units}"

    # adjust for origin, margin, and mirror in y
    y = canvas.height - (@y - origin.y) + canvas.margin
    # add the units
    #y = "#{y}#{units}"

    switch @tool.shape
      when'C'
        #console.log "drawing circular pad at #{@x}, #{@y} with dia #{@tool.params.dia}"
        pad = drawing.circle("#{@tool.params.dia}")
        pad.center(x, y)

      when 'R'
        #console.log "drawing rectangular pad at #{@x}, #{@y} with size #{@tool.params.sizeX}, #{@tool.params.sizeY}"
        pad = drawing.rect("#{@tool.params.sizeX}", "#{@tool.params.sizeY}")
        # center doesn't work with units, so adapt
        moveX = "#{parseFloat(x) - @tool.params.sizeX/2}"
        moveY = "#{parseFloat(y) - @tool.params.sizeY/2}"
        # move
        pad.move(moveX,moveY)
      when 'O'
        console.log "obround pad"
      when 'P'
        console.log "polygon pad"
      else
        console.log "unrecognized shape"

    if @tool.params.holeX?
      # positve mask for the pad itself
      p = pad.clone().fill {color: '#fff'}
      # negative mask for the hole
      h = null
      # rectangle or circle
      if @tool.params.holeY?
        h = drawing.rect(@tool.params.holeX, @tool.params.holeY)
      else
        h = drawing.circle(@tool.params.holeX)
      # center the hole and fill properly
      h.center(pad.cx(), pad.cy()).fill {color: '#000'}
      # mask the hole out
      m = drawing.mask().add(p).add(h)
      pad.maskWith m

# trace class for Layer
class Trace extends LayerObject
  print: ->
    console.log "trace created from #{@x}, #{@y} to #{@coord.x}, #{@coord.y}"

  getRange: ->
    [@x, @y, @coord.x, @coord.y]

  # draw to SVG
  # parameters are the drawing object,
  # an origin object with keys x and y
  # a canvas object with keys width, height, and margin
  # the units for the drawing
  draw: (drawing, origin, canvas, units) ->
    trace = null

    # adjust for origin and margin in x
    x1 = @x - origin.x + canvas.margin
    x2 = @coord.x - origin.x + canvas.margin
    # add the units
    #x1 = "#{x1}#{units}"
    #x2 = "#{x2}#{units}"

    # adjust for origin and margin in y
    y1 = canvas.height - (@y - origin.y) + canvas.margin
    y2 = canvas.height - (@coord.y - origin.y) + canvas.margin
    # add the units
    #y1 = "#{y1}#{units}"
    #y2 = "#{y2}#{units}"

    # if the tool shape is a circle, then we do a line with rounded caps
    if @tool.shape is 'C'
      trace = drawing.line()
      # first param is circle dia
      trace.stroke {
        width: "#{@tool.params.dia}"
        linecap: 'round'
      }
      # plot the stroke to the end
      trace.plot x1, y1, x2, y2

    # if the tool shape is a rect, then we gotta get fancy
    else if @tool.shape is 'R'
      console.log "fancy trace"

# fill class
class Fill extends LayerObject
  # overload the constructor because a fill is different
  constructor: (@path) ->

  # draw will get interesting
  draw: (drawing, origin, canvas, units) ->
    console.log 'drawing fill'
    # path string to pass to SVG
    drawPath = ''
    # process coordinates for origin, margin, and mirror
    index = 0
    while index < @path.length
      # move to command
      if @path[index] is 'M'
        drawPath += 'M'
        index++
        # two coordinates will follow: x and y
        # x (origin and margin)
        drawPath += "#{@path[index] - origin.x + canvas.margin} "
        index++
        # y (origin, margin, and mirror)
        drawPath += "#{canvas.height - (@path[index] - origin.y) + canvas.margin}"
        index++
      # line to command
      else if @path[index] is 'L'
        drawPath += 'L'
        index++
        # two coordinates will follow: x and y
        # x (origin and margin)
        drawPath += "#{@path[index] - origin.x + canvas.margin} "
        index++
        # y (origin, margin, and mirror)
        drawPath += "#{canvas.height - (@path[index] - origin.y) + canvas.margin}"
        index++
      # arc to command
      else if @path[index] is 'A'
        # first five items parameters are A, rx, ry, xAxisRot, largeArcFlag, and sweepFlag
        # push them without modification
        for p in @path[index...index+5]
          drawPath += "#{p} "
        index += 5
        # next two are the x end and the y end... transform accordingly
        # x (origin and margin)
        drawPath += "#{@path[index] - origin.x + canvas.margin} "
        index++
        # y (origin, margin, and mirror)
        drawPath += "#{canvas.height - (@path[index] - origin.y) + canvas.margin}"
        index++
      # close region command
      else if @path[index] is 'Z'
        drawPath += 'Z'
        index++
      # else we are confused
      else
        throw "unrecognized path command #{@path[index]}"

    # create a path with the processed string
    path = drawing.path drawPath
    path.fill {color: '#000'}
    path.stroke {width: 0}



# layer class
class root.Layer
  constructor: (@name) ->
    @layerObjects = []
    @minX = null
    @minY = null
    @maxX = null
    @maxY = null

  setUnits: (u) ->
    if u is 'in' then @units = 'in' else if u is 'mm' then @units = 'mm'

  getSize: ->
    [@minX, @maxX, @minY, @maxY]

  # add a trace given a tool, start points, and the trace coordinates
  addTrace: (tool, startX, startY, c) ->
    # tool has to be a circle or a rectangle without a hole
    unless tool.shape is 'C' or tool.shape is 'R' then throw "cannot create trace with #{tool.shape} (tool #{tool.code})"
    if tool.holeX? then throw "cannot create trace with a holed tool (tool #{tool.code})"

    # for now let's just stick to lines
    t = new Trace tool, startX, startY, c
    @layerObjects.push t
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

  addPad: (tool, x, y) ->
    # create the pad
    p = new Pad tool, x, y
    @layerObjects.push p
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

  addFill: (path) ->
    # create the fill
    f = new Fill path
    @layerObjects.push f

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

    origin = {
      x: @minX
      y: @minY
    }
    canvas = {
      width: @maxX - @minX
      height: @maxY - @minY
      margin: 0.5
    }
    # create an SVG object
    totW = 2*canvas.margin+canvas.width
    totH = 2*canvas.margin+canvas.height
    svg = SVG(id).size("#{totW}#{@units}", "#{totH}#{@units}").viewbox(0,0,totW,totH)

    # draw all the objects
    o.draw(svg, origin, canvas, @units) for o in @layerObjects

    # return the id of the svg object
    svg
