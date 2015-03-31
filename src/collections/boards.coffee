# collection of the top and bottom board
# require Renders prototype collection, board model, and builder worker
Renders = require './renders'
Board = require '../models/board'
builder = new Worker './../workers/board-worker.coffee'

class Boards extends Renders
  model: Board

  initialize: ->
    # attach an event listener to the board builder
    @attachBuilderHandler()
    # when a board triggers a buildNeeded event, build it
    @on 'buildNeeded', @buildBoard
    # call the parent initialize
    super()

  buildBoard: (board) ->
    builder.postMessage {
      name: board.get 'name'
      layers: board.get 'boardLayers'
    }

  attachBuilderHandler: ->
    _self = @
    handler = (e) -> _self.convert e.data.name, e.data.svgObj
    builder.addEventListener 'message', handler, false

module.exports = Boards
