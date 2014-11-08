# identify a layer by its filename

# require the layer options
layerOpts = require './layer-options'

# some regexp constants
reTOP = /top/i
reBOTTOM = /bottom/i
reSILK = /(silk)|(ss)/i
reMASK = /(soldermask)|(sm)/i
rePASTE = /(paste)|(sp)|(pm)/i

module.exports = (name) ->
  type = ''
  # loop through the layer types, and if one of the regexps hits, then return
  for opt in layerOpts
    if opt.match.test name
      return opt.val
  # else, we still haven't figured it out, so we'll get a little fancier
  name = name.split('.')[0]
  # top or bottom
  # also grab the length of the match
  if len = name.match(reTOP)?[0]?.length then type = 't'
  else if len = name.match(reBOTTOM)?[0]?.length then type = 'b'
  # function
  if reSILK.test name then type += 'ss'
  else if reMASK.test name then type += 'sm'
  else if rePASTE.test name then type += 'sp'
  # assume it's copper if filename is 'top' or 'bottom' by itself
  else if name.length is len then type += 'cu' 
  # make sure we don't return something invalid
  unless _.find layerOpts, { val: type } then type = 'drw'
  # return what we found
  type
