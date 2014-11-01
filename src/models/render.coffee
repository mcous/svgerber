# prototype render model for individual layers as well as board stackups

class Render extends Backbone.Model
  # common defaults
  defaults: {
    # both layers and boards will have a name
    # boards will have 'top' and 'bottom', layers will have filenames
    name: ''
    # both will have an svg string
    svg: ''
  }
  
module.exports = Render
