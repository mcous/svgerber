# color picker view / controller for the boards

# pull in color options
colorOpts = require '../color-options'

module.exports = Backbone.View.extend {
  tagName: 'div'
  className: 'ColorPicker'
  template: _.template $('#color-picker-template').html()

  events: {
    # color button click
    'click .ColorPicker--btn': 'handleColorChange'
    # show color picker button
    'click #show-color-picker-btn': 'toggleColorPicker'
  }

  # on initialization, it should listen to the board collection for changes
  initialize: ->
    # listen to the board collection for changes
    @listenTo @collection.collection, 'renderRemove', @handleBoardRemoval

  render: ->
    @$el.html @template {
      cfColors: colorOpts.cf
      smColors: colorOpts.sm
      ssColors: colorOpts.ss
    }
    @$el.find('.ColorPicker--box').addClass 'is-retracted'
    @$el.find('.ColorPicker--btn').each ->
      btn = $ @
      layer = btn.parent().attr('id')[6..7]
      opt = btn.html()
      color = colorOpts[layer][opt]
      btn.css('background-color', color.bg).css 'color', color.txt
    # disable buttons as necessary
    @getCurrentColors()
    # return self
    @

  getCurrentColors: ->
    boardStyles = @collection.collection.pluck 'style'
    style = boardStyles[0]
    for layer in [ 'cf', 'sm', 'ss' ]
      reStyle = new RegExp "\.Board--#{layer} { color: .*?;"
      match = style.match reStyle
      color = match[0][20...-1]
      opts = colorOpts[layer]
      opt = _.findKey opts, _.find opts, (o) -> o.bg is color
      @$el.find("#board-#{layer}-color-buttons").children().each ->
        if (btn = $ @).html() is opt then btn.prop 'disabled', true

  handleColorChange: (e) ->
    btn = $ e.currentTarget
    # re-enable other buttons and disable clicked button
    btn.prop('disabled', true).siblings().prop 'disabled', false
    # delay a little to let the enables and disables stick
    _.delay (self) ->
      # get the color button that was clicked
      layer = btn.parent().attr('id')[6..7]
      opt = btn.html()
      color = colorOpts[layer][opt].bg
      switch layer
        when 'cf'
          newStyle = ".Board--cf { color: #{color}; }"
          reStyle = /\.Board--cf {.*?}/
        when 'sm'
          newStyle = ".Board--sm { color: #{color}; opacity: 0.75; }"
          reStyle = /\.Board--sm {.*?}/
        when 'ss'
          newStyle = ".Board--ss { color: #{color}; }"
          reStyle = /\.Board--ss {.*?}/
      # replace the appropriate part of the svg string
      self.collection.collection.each (board) ->
        board.set 'style', board.get('style').replace reStyle, newStyle
    # end delay function
    , 10, @

  handleBoardRemoval: ->
    boardsExist = false
    @collection.collection.each (board) ->
      if board.get('svg').length then boardsExist = true
    if not boardsExist then @remove()

  toggleColorPicker: ->
    picker = $ '.ColorPicker--box'
    btnIcon = $('#show-color-picker-btn').children('.octicon')
    # if it's retracted, remove the retracted class and switch the button icon
    if picker.hasClass 'is-retracted'
      picker.removeClass 'is-retracted'
      @changeIcon btnIcon, 'octicon-chevron-up'
    # else, make sure that the color picker exists
    else if picker.length
      picker.addClass 'is-retracted'
      @changeIcon btnIcon, 'octicon-chevron-down'

  # change icon helper
  changeIcon: (element, newIcon) ->
    element.removeClass( (i, c) -> c.match(/octicon-\S+/g)?.join ' ')
      .addClass newIcon
}
