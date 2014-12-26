# prototype render model for individual layers as well as board stackups

class Render extends Backbone.Model
  # common defaults
  defaults: {
    # both layers and boards will have a name
    # boards will have 'top' and 'bottom', layers will have filenames
    name: ''
    # both will have an svg string, obj, and encoded string
    svg: ''
    svgObj: null
    svg64: false
    # any warnings from gerber-to-svg
    warnings: []
  }
  
module.exports = Render
