# build a board from layers (as svg objects)
# require lodashes deep cloner
cloneDeep = require 'lodash.clonedeep'
uniqueid = require 'lodash.uniqueid'

module.exports = (name, layers) ->
  # we need at least copper and edge cuts
  if not (layers.cu? and layers.edge?) then return {}
  # result
  boardDefs = { defs: { _: [] } }
  boardGroup = { g: { _: [] } }
  bbox = [ Infinity, Infinity, -Infinity, -Infinity ]
  addBbox = (b) ->
    if b[0] < bbox[0] then bbox[0] = b[0]
    if b[1] < bbox[1] then bbox[1] = b[1]
    if b[2] > bbox[2] then bbox[2] = b[2]
    if b[3] > bbox[3] then bbox[3] = b[3]

  groups = { cu: null, sm: null, ss: null, sp: null, edge: null, drill: [] }
  # collect defs and gather bboxes
  units = null
  for ly, obj of layers
    add = (o) ->
      # get defs and group
      defs = []
      for item in o.svg._
        if item.defs? then defs = item.defs._
        else if item.g?
          if ly is 'drill' then groups.drill.push item
          else groups[ly] = item
      # do a unit check
      if o.svg.width.match /in/
        if not units? then units = 'in'
        else if units isnt 'in' then throw new Error "unit mismatch"
      else if o.svg.width.match /mm/
        if not units? then units = 'mm'
        else if units isnt 'mm' then throw new Error "unit mismatch"
      # add the bounding box
      v = o.svg.viewBox
      addBbox [ v[0], v[1], v[2]+v[0], v[3]+v[1] ]
      # add the defs
      for d in defs
        boardDefs.defs._.push d
    # drill files come in as an array
    if Array.isArray obj
      add o for o in obj
    else add obj
  # start with the board itself
  boardGroup.g._.push {
    rect: {
      class: 'Board--fr4'
      x: bbox[0]
      y: bbox[1]
      width: bbox[2]-bbox[0]
      height: bbox[3]-bbox[1]
      fill: 'dimgrey'
    }
  }
  # now add the copper (delete the transform first)
  cu = cloneDeep groups.cu
  delete cu.g.transform
  cu.g.class = 'Board--copper'
  cu.g.color = 'goldenrod'
  boardGroup.g._.push cu
  # then comes the soldermask
  if groups.sm?
    # get an id for the mask
    id = uniqueid "board-#{name}-mask-"
    # start a mask with a rect to cover the bbox
    mask = { mask: { id: id, _: [] } }
    mask.mask._.push {
      rect: {
        x: bbox[0]
        y: bbox[1]
        width: bbox[2]-bbox[0]
        height: bbox[3]-bbox[1]
        fill: '#fff'
      }
    }
    # clone the solder mask layer, delete the transform, and color it to keep
    sm = cloneDeep groups.sm
    delete sm.g.transform
    sm.g.color = '#000'
    mask.mask._.push sm
    # push the mask to the defs
    boardDefs.defs._.push mask
    # create a rect to add the the group
    boardGroup.g._.push {
      rect: {
        x: bbox[0]
        y: bbox[1]
        width: bbox[2]-bbox[0]
        height: bbox[3]-bbox[1]
        class: 'Board--mask'
        fill: 'indigo'
        opacity: '0.7'
        mask: "url(##{id})"
      }
    }
  # then the silkscreen
  if groups.ss?
    ss = cloneDeep groups.ss
    delete ss.g.transform
    ss.g.class = 'Board--silk'
    ss.g.color = 'white'
    boardGroup.g._.push ss
  # then the paste
  if groups.sp?
    sp = cloneDeep groups.sp
    delete sp.g.transform
    sp.g.class = 'Board--paste'
    sp.g.color = 'silver'
    boardGroup.g._.push sp
  # then the edge cuts
  out = cloneDeep groups.edge
  delete out.g.transform
  out.g.class = 'Board--outline'
  boardGroup.g._.push out
  # then the drill hits
  if groups.drill?.length
    # group up everyone again
    id = uniqueid "board-#{name}-drill-"
    # wrap the current group
    boardGroup.g.mask = "url(##{id})"
    boardGroup = { g: { _: [ boardGroup ] } }
    mask = { mask: { id: id, class: 'Board--drill', color: '#000', _: [] } }
    # bbox rect
    mask.mask._.push {
      rect: {
        x: bbox[0]
        y: bbox[1]
        width: bbox[2]-bbox[0]
        height: bbox[3]-bbox[1]
        fill: '#fff'
      }
    }
    for d in groups.drill
      drl = cloneDeep d
      delete drl.g.transform
      drl.g.class = 'Board--drill'
      mask.mask._.push drl
    # push mask to the defs
    boardDefs.defs._.push mask
  # now we should be done, so recalculate that transform
  boardGroup.g.transform = """
  translate(0,#{bbox[1]+bbox[3]}) scale(1,-1)
  """
  # finally add a little red bow
  width = bbox[2] - bbox[0]
  height = bbox[3] - bbox[1]
  xml = {
    svg: {
      xmlns: 'http://www.w3.org/2000/svg'
      version: '1.1'
      'xmlns:xlink': 'http://www.w3.org/1999/xlink'
      width: "#{width}#{units}"
      height: "#{height}#{units}"
      viewBox: [ bbox[0], bbox[1], width, height ]
      id: uniqueid "board-#{name}-"
      _: [ boardDefs, boardGroup]
    }
  }
  xml
