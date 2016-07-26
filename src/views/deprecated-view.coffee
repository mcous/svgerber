# svgerber is dead
# long live viewer.tracespace.io

REDIRECT_URL = 'http://viewer.tracespace.io'
REDIRECT_WAIT = 7

remainingTime = REDIRECT_WAIT

class DeprecatedView extends Backbone.View
  tagName: 'div'
  className: 'Deprecated'

  # cache the template
  template: _.template $('#deprecated-template').html()

  events: {
    'click .Deprecated--leave-btn': 'leave',
    'click .Deprecated--stay-btn': 'stay'
  }

  initialize: ->
    remainingTime = REDIRECT_WAIT

    tick = =>
      if --remainingTime is 0
        @leave()
      else
        @setRemainingTime(remainingTime)

    @countdown = setInterval(tick, 1000)

  setRemainingTime: (time) ->
    units = if time isnt 1 then 'seconds' else 'second'

    @$("[data-hook='time']").html "#{time} #{units}"

  render: ->
    @$el.html @template()
    @setRemainingTime(REDIRECT_WAIT)
    this

  stay: ->
    clearInterval @countdown
    @$el.remove()

  leave: ->
    window.location.assign REDIRECT_URL

module.exports = DeprecatedView
