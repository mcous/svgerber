# require board model, converter worker, and builder worker
Board = require '../models/board'
converter = new Worker './../gerber-worker.coffee'
builder = new Worker './../board-worker.coffee'

module.exports = Backbone.Collection.extend {
  model: Board

  initialize: ->
    # attach an event listener to the svg converter
    @attachConverterHandler()
    # attach an event listener to the board builder
    @attachBuilderHandler()
    # when a board triggers a buildNeeded event, build it
    @on 'buildNeeded', @buildBoard

  buildBoard: (board) ->
    console.log "building #{board.get 'type'}"
    builder.postMessage {
      name: board.get 'type'
      layers: board.get 'boardLayers'
    }

  attachConverterHandler: ->
    _self = @
    handler = (e) ->
      board = _self.findWhere { type: e.data.filename }
      board.set 'svg', e.data.svgString
      board.trigger 'render', board
    converter.addEventListener 'message', handler, false

  attachBuilderHandler: ->
    handler = (e) ->
      converter.postMessage { filename: e.data.name, gerber: e.data.svgObj }
    builder.addEventListener 'message', handler, false

}
