# webworker to build a board from layers
# pull in the build board function

build = require './build-board.coffee'

self.addEventListener 'message', (e) ->
  name = e.data.name
  layers = e.data.layers
  boardObj = build name, layers
  self.postMessage { name: name, svgObj: boardObj }
, false
