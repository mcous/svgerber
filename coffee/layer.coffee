# classes to represent a layer of a circuit board

# requires the svg.js library
SVG = require 'svg.js'

# layer object (pad or trace)
class LayerObject
  # constructor takes in the tool shape, start position, parameters
  constructor: (params = {}) ->
    @["#{key}"] = value for key, value of params

  print: ->
    console.log "#{key}: #{value}" for key, value of params

  draw: (svgItem) ->
    # return the bounding box
    svgItem.bbox()

# pad class for Layer
class Pad extends LayerObject
  print: ->
    console.log "#{@tool.shape} pad created at #{@x}, #{@y}"

  # draw to SVG
  draw: (drawing) ->
    pad = null

    switch @tool.shape
      when'C'
        pad = drawing.circle(@tool.dia)
        pad.center(@x, @y)

      when 'R'
        pad = drawing.rect(@tool.sizeX, @tool.sizeY)
        pad.center @x, @y
      when 'O'
        console.log "obround pad"
      when 'P'
        console.log "polygon pad"
      else
        console.log "unrecognized shape"

    if @tool.holeX?
      # positve mask for the pad itself
      p = pad.clone().fill {color: '#fff'}
      # negative mask for the hole
      h = null
      # rectangle or circle
      if @tool.holeY?
        h = drawing.rect(@tool.holeX, @tool.holeY)
      else
        h = drawing.circle(@tool.holeX)
      # center the hole and fill properly
      h.center(pad.cx(), pad.cy()).fill {color: '#000'}
      # mask the hole out
      m = drawing.mask().add(p).add(h)
      pad.maskWith m

    # pads don't have stroke
    pad.stroke {width: 0}
    pad.addClass 'svg-no-stroke'

    # check if we're clearing
    if @clear is on
      pad.addClass 'svg-fill-clear'
      pad.fill '#fff'
    else
      pad.attr 'class', 'svg-fill-draw'
      pad.fill '#000'

    # call the parent draw method
    super pad

# path based LayerObjects
class PathObject extends LayerObject
  # convert a pathArray into a string with coordinates fixed
  pathArrayToString: (pathArray) ->
    pathString = pathArray.join ' '

# trace class for Layer
class Trace extends PathObject
  print: ->
    console.log "trace created from #{@x}, #{@y} to #{@coord.x}, #{@coord.y}"

  # draw the path and fill it in
  draw: (drawing) ->
    #console.log 'drawing path'
    # path string to pass to SVG
    path = @pathArrayToString @pathArray

    # create a path with the processed string
    path = drawing.path path
    if @tool.dia? then path.stroke {width: @tool.dia, linecap: 'round', linejoin: 'round'}
    else throw "rectangular trace apertures unimplimented in this reader"

    # no fill
    path.fill {color: 'transparent', opacity: 0}
    #check if we're clearing
    if @clear is on
      path.addClass 'svg-stroke-clear'
      path.stroke '#fff'
    else
      path.addClass 'svg-stroke-draw'
      path.stroke '#000'
    # call the parent draw
    super path

# fill class
class Fill extends PathObject
  # draw the path and fill it in
  draw: (drawing) ->
    #console.log 'drawing fill'
    # path string to pass to SVG
    path = @pathArrayToString @pathArray

    # create a path with the processed string
    path = drawing.path path
    path.stroke {width: 0}
    path.addClass 'svg-no-stroke'
    # check if we're clearing
    if @clear is on
      path.addClass 'svg-fill-clear'
      path.fill '#fff'
    else
      path.addClass 'svg-fill-draw'
      path.fill '#000'

    # call the parent
    super path

# layer class
#class root.Layer
class Layer
  constructor: (id) ->
    @svg = SVG id
    @group = @svg.group()
    @layerObjects = []
    @index = 0

  setUnits: (u) ->
    if u is 'in' then @units = 'in' else if u is 'mm' then @units = 'mm'

  # add a trace given a tool, start points, and the trace coordinates
  addTrace: (params) ->
    # tool has to be a circle or a rectangle without a hole
    unless params.tool.shape is 'C' or params.tool.shape is 'R' then throw "cannot create trace with #{tool.shape} (tool #{tool.code})"
    if params.tool.holeX? then throw "cannot create trace with a holed tool (tool #{tool.code})"

    # for now let's just stick to lines
    t = new Trace params
    # draw the trace
    t.draw @group

  addPad: (params) ->
    # create the pad
    p = new Pad params
    # draw the pad
    p.draw @group

  addFill: (params) ->
    # create the fill
    f = new Fill params
    # draw fill
    f.draw @group
    #@layerObjects.push f

  drawNext: () ->
    # resize the svg
    box = @group.bbox()
    @svg.size("#{box.width}#{@units}", "#{box.height}#{@units}").viewbox 0,0,box.width, box.height
    # transform the items to fit in the svg and mirror the y
    @group.transform {
      x: -box.x
      y: box.y2
      scaleY: -1
    }
    # return the svg
    @svg

# export to node or window
if module? then module.exports = Layer else @.Layer = Layer
