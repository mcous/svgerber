# gerber layer model
module.exports = Backbone.Model.extend {
  defaults: {
    filename: ''
    gerber: ''
    type: 'oth'
    svg: {}
  }

  events: {
    # on filename change, get the layer type

    # on gerber change, update the svg object
  }
}
