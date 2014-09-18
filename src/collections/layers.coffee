# backbone collection of all layers
Layer = require '../models/layer'
module.exports = Backbone.Collection.extend {
  model: Layer
}
