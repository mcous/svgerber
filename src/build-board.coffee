# new board builder
# hopefully less janky than the first one

# make sure we don't have overlapping ids
unique = 0
uniqueId = -> unique++

# board type matching
reCOPPER = /cu/
reMASK = /sm/
reSILK = /ss/
rePASTE = /sp/
reEDGE = /out/
reDRILL = /drl/

# board combine function
# takes the board name and board layers
module.exports = (name, layers = []) ->
  copper = null
  mask = null
  silk = null
  paste = null
  edge = null
  drill = []

  # resulting svg is going to have attributes, a def section, a drawing, and a
  # bounding box
  attr = {}
  defs = []
  draw = []
  bbox = [ Infinity, Infinity, -Infinity, -Infinity ]
  units = 'px'
  scale = null
  addVboxToBbox = (v) ->
    xMax = v[2] + v[0]
    yMax = v[3] + v[1]
    if v[0] < bbox[0] then bbox[0] = v[0]
    if v[1] < bbox[1] then bbox[1] = v[1]
    if xMax > bbox[2] then bbox[2] = xMax
    if yMax > bbox[3] then bbox[3] = yMax
  getVboxFromBbox = -> [ bbox[0], bbox[1], bbox[2]-bbox[0], bbox[3]-bbox[1] ]

  # gather all the layers to combine there defs, bboxes, and attributes
  # we're also going to push the layers themselves to the defs
  for layer in layers
    # get layer type
    ly = layer.type
    # xml object and make sure we've got something
    xml = layer.svgObj
    continue if not xml.svg?
    # collect the bbox
    addVboxToBbox xml.svg.viewBox
    # grab the units
    u = xml.svg.width.match(/(in)|(mm)/)?[0]
    if units is 'px' then units = u
    else if u isnt units then return {}
    # grab the units to vbox scale
    vbScale = parseFloat(xml.svg.width)/xml.svg.viewBox[2]
    if not scale? then scale = vbScale
    else if Math.abs(vbScale-scale) > 0.0000001 then return {}
    # toss the viewBox as well as the width, height and id
    delete xml.svg.viewBox
    delete xml.svg.width
    delete xml.svg.height
    delete xml.svg.id
    # gather the rest of the attributes
    for key, val of xml.svg
      attr[key] = val if not attr[key]? and key isnt '_'
    # collect the defs and group
    # hopefully a group and defs will be the only children of the svg node
    layerId = "#{name}-#{ly}_#{uniqueId()}"
    for node in xml.svg._
      # collect the defs
      if node.defs? then defs.push d for d in node.defs._
      # collect the group
      else if node.g?
        # delete the transform and any fill or stroke properties
        delete node.g.transform
        # add a better id
        node.g.id = layerId
        defs.push node
    # now, it is possible that there will be multiple drill files. deal with it
    if reCOPPER.test ly then copper = layerId
    else if reMASK.test ly then mask = layerId
    else if reSILK.test ly then silk = layerId
    else if rePASTE.test ly then paste = layerId
    else if reEDGE.test ly then edge = layerId
    else if reDRILL.test ly then drill.push layerId

  # we need at least a copper layer to do this
  unless copper? then return {}

  # viewbox and covering rectangle convenience function
  vbox = getVboxFromBbox()
  bboxRect = (cls = 'Board--cover', fill='currentColor') ->
    {
      rect: {
        class: cls
        fill: fill
        x: vbox[0]
        y: vbox[1]
        width: vbox[2]
        height: vbox[3]
      }
    }

  # the first layer of the board stackup is the board itself
  draw.push bboxRect('Board--board')

  # the second layer is the copper
  draw.push { use: { class: 'Board--cu', 'xlink:href': "##{copper}" } }

  # if we've got a soldermask
  if mask?
    # mask it with the copper for copper finish
    cuFinishId = "#{name}-sm_#{uniqueId()}"
    defs.push {
      mask: {
        id: cuFinishId
        color: '#fff'
        _: [ { use: { 'xlink:href': "##{copper}" } } ]
      }
    }
    draw.push {
      use: {
        class: 'Board--cf'
        mask: "url(##{cuFinishId})"
        'xlink:href': "##{mask}"
      }
    }
    # now build group for the color and the silkscreen (if it exists) and
    # mask away the soldermask holes
    smId = "#{name}-sm_#{uniqueId()}"
    defs.push { mask: { id: smId, color: '#000', _: [
          bboxRect null, '#fff'
          { use: { 'xlink:href': "##{mask}" } }
        ]
      }
    }
    smPos = { g: { mask: "url(##{smId})", _: [ bboxRect 'Board--sm' ] } }
    # add the silkscreen if it exists
    if silk? then smPos.g._.push {
      use: { class: 'Board--ss', 'xlink:href': "##{silk}" }
    }
    # push the soldermask to the stack
    draw.push smPos

  # if we've got solderpaste, push it to the drawing
  if paste? then draw.push {
    use: { class: 'Board--sp', 'xlink:href': "##{paste}" }
  }

  # add edge cuts if we gottem
  if edge? then draw.push {
    use: { class: 'Board--out', 'xlink:href': "##{edge}" }
  }

  # finally, we may have some drills
  drlId = null
  if drill.length
    drlId = "#{name}-drl_#{uniqueId()}"
    drlMask = { mask: { id: drlId, color: '#000', _: [bboxRect null, '#fff'] } }
    for d in drill
      drlMask.mask._.push { use: { 'xlink:href': "##{d}" } }
    # push the mask to the defs
    defs.push drlMask

  # return object
  # flip vertically always and horizontally as well if bottom of board
  if name is 'bottom' then trans = """
    translate(#{bbox[2]+bbox[0]},#{bbox[3]+bbox[1]}) scale(-1,-1)
  """
  else trans = "translate(0,#{bbox[3]+bbox[1]}) scale(1,-1)"
  # drawing
  draw = { g: { transform: trans, _: draw } }
  if drlId then draw.g.mask = "url(##{drlId})"
  # svg
  svg = attr
  svg.class = 'Board'
  svg.viewBox = getVboxFromBbox()
  svg.width = "#{svg.viewBox[2]*scale}#{units}"
  svg.height = "#{svg.viewBox[3]*scale}#{units}"
  svg._ = []
  svg._.push { defs: { _: defs } } if defs.length
  svg._.push draw if draw.g._.length
  # return
  { svg: svg }
