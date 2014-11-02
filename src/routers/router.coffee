# router
# navigation sugar
navHeight = $('#main-nav').height()

module.exports = Backbone.Router.extend {

  initialize: ->
    @route /.*/, @scroll

  scroll: (route) ->
    frag = Backbone.history.fragment
    anchor = ".#{frag}-anchor"
    $('html, body').animate {
      scrollTop: if frag then $(anchor).offset().top - 1.15*navHeight else 0
    }, 300
}
