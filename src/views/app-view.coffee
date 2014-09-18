# hello world
module.exports = Backbone.View.extend {
  initialize: ->
    console.log 'hello 42'
    @render()

  render: ->
    $('body').prepend '<p>always bring a towel</p>'
}
