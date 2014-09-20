# main svgerber site application
# svgerber.cousins.io

# requires jquery, backbone, and lodash

# load the backbone application view to start the app
AppView = require './views/app'
appView = new AppView()

# btoa polyfill
unless typeof window.btoa is 'function'
  window.btoa = (require 'Base64').btoa

# board colors
COLORS = {
  cu: {
    bare:    { bg: '#C87533',       txt: 'white' }
    gold:    { bg: 'goldenrod',     txt: 'white' }
    'Ni/Au': { bg: 'whitesmoke',    txt: 'black' }
    hasl:    { bg: 'silver',        txt: 'black' }
  }
  sm: {
    red:    { bg: 'darkred',    txt: 'white' }
    orange: { bg: 'darkorange', txt: 'black' }
    yellow: { bg: '#FFFF66',    txt: 'black' }
    green:  { bg: 'darkgreen',  txt: 'white' }
    blue:   { bg: 'navy',       txt: 'white' }
    purple: { bg: 'indigo',     txt: 'white' }
    black:  { bg: 'black',      txt: 'white' }
    white:  { bg: 'white',      txt: 'black' }
  }
  ss: {
    red:    { bg: 'red',    txt: 'white' }
    yellow: { bg: 'yellow', txt: 'black' }
    green:  { bg: 'green',  txt: 'white' }
    blue:   { bg: 'blue',   txt: 'white' }
    black:  { bg: 'black',  txt: 'white' }
    white:  { bg: 'white',  txt: 'black' }
  }
  built: false
  defaults: { cu: 'gold', sm: 'green', ss: 'white' }
}


# document elements
# url paste buttons
docPasteBtn = $ '#url-paste-btn'
docPasteSubmitBtn = $ 'button[name="url-paste-submit-btn"]'
docPasteCancelBtn = $ 'button[name="url-paste-cancel-btn"]'
docPasteForm = $ '#url-paste-form'
docPasteText = $ '#url-paste'

# board color picker buttons
boardColorMainBtn = $ 'button[name="board-color-btn"]'
boardColorContainer = $ '#board-output-color'
# color picker buttons
boardColorPickerBtn = $ '.ColorPicker--btn'

# nav links
nav = $ '#main-nav'
navHome = $('#nav-top').children 'a.Nav--brand'
navFiles = $ '#nav-filelist'
navSvgs = $ '#nav-output, #nav-layers'
# nav buttons
navButtons = $ 'Nav--linkButton'

changeIcon = (element, newIcon) ->
  element.removeClass( (i, c) -> c.match(/octicon-\S+/g)?.join ' ')
    .addClass newIcon

# (re)start the app
restart = ->
  # reset the processed flag
  processed = false
  # clear out the internal lists
  fileList = {}
  # remove the file listings from the DOM and hide the section
  docFileList.addClass 'is-hidden'
  docFileList.children('ul').children().not('.is-js-template').remove()
  # remove the board renders
  removeLayerOutput()
  # rehide to color selector
  boardColorContainer.addClass('is-retracted').removeClass 'is-extended'
  # remove the restart icon from the home nav link and disable filelist link
  changeIcon navHome, 'octicon-jump-up'
  navFiles.addClass 'is-disabled'

# build the file list output and internal filelist object
buildFileListOutput = (filenames) ->
  # show the file list and enable the nav icon
  if docFileList.hasClass 'is-hidden'
    docFileList.removeClass 'is-hidden'
    navFiles.removeClass 'is-disabled'
    # add the restart icon to the home nav link
    changeIcon navHome, 'octicon-sync'
    # scroll to the filelist
    scrollTo docFileList

# parse a standard github url into an github api url
apiUrl = (url) ->
  # strip off the http and split by /
  url = url.match(/github\.com\S+/)?[0].split '/'
  if url?.length
    api = 'https://api.github.com/repos'
    owner = url[1]
    repo = url[2]
    branch = url[4]
    path = url[5..].join '/'
    url = "#{api}/#{owner}/#{repo}/contents/#{path}?ref=#{branch}"
  else
   false

# get urls
processUrls = (urls) ->
  for u, i in docPasteText.val().split '\n'
    u = apiUrl u
    if u then $.ajax {
      type: 'GET'
      url: u
      contentType: 'application/vnd.github.VERSION.raw'
      dataType: 'json'
      success: (data) ->
        fileList[data.name] = { string: atob data.content }
        buildFileListOutput [ data.name ]
        data = null
    }

# rest the paste box
resetPaste = ->
  docPasteText.val ''
  docPasteForm.addClass 'is-hidden'
  # return false
  false

# take care of urls pasted in
handlePaste = ->
  urls = docPasteText.val().split '\n'
  resetPaste()
  processUrls urls
  false

# build the color selectors for the board output
buildColorPicker = ->
  unless COLORS.built
    # loop through copper, soldermask, and silkscreen
    for elem in [ 'cu', 'sm', 'ss' ]
      # find the copper color button template
      temp = $("#board-#{elem}-color-buttons").children('button.is-js-template')
      for c, code of COLORS[elem]
        newBtn = temp.clone().removeClass 'is-js-template'
        newBtn.css('background-color', code.bg).css 'color', code.txt
        newBtn.html c
        if c is COLORS.defaults[elem] then newBtn.prop 'disabled', true
        temp.before newBtn
    # color picker buttons
    boardColorPickerBtn = $ '.ColorPicker--btn'
    # attach event listener
    boardColorPickerBtn.on 'click', changeColor
    # set the built flag
    COLORS.built = true

# encode for download
encodeForDownload = ->
  containers = $('.BoardContainer').not('.is-js-template')
  containers.each ->
    c = $ this
    drawDiv = c.children('.LayerDrawing')
    svg = drawDiv.html()
    svg64 = "data:image/svg+xml;base64,#{btoa svg}"
    if c.attr('id') is 'board-top-render'
      btn = $('#download-top-btn')
    else if c.attr('id') is 'board-bottom-render'
      btn = $('#download-bottom-btn')
    btn.attr 'href', svg64
    btn.removeClass 'is-disabled'

changeColor = (clicked) ->
  # get the elements for board stlyes
  style = $ '.Board--style'
  # use text because svg is xml, not html (and makes safari unhappy)
  styleString = style.first().text()
  # get the element that we're changing to color
  clicked = $ clicked.target
  clickId = clicked.parent().attr 'id'
  if clickId.match /cu/
    color = COLORS.cu[clicked.html()].bg
    newStyle = ".Board--finish { color: #{color}; }"
    reStyle = /\.Board--finish {.*}/
  else if clickId.match /ss/
    color = COLORS.ss[clicked.html()].bg
    newStyle = ".Board--ss { color: #{color}; }"
    reStyle = /\.Board--ss {.*}/
  else if clickId.match /sm/
    color = COLORS.sm[clicked.html()].bg
    opacity = styleString.match(/opacity:.*;/)?[0]
    newStyle = ".Board--sm { color: #{color}; #{opacity} }"
    reStyle = /\.Board--sm {.*}/
  # clear any disables
  clicked.siblings().prop 'disabled', false
  # disabled current
  clicked.prop 'disabled', true
  # replace the style
  style.text styleString.replace reStyle, newStyle
  # encode new
  encodeForDownload()

# navigation sugar
navHeight = nav.height()
# scroll to
scrollTo = (selector, cb) ->
  $('html, body').animate {
    scrollTop: if selector then $( selector ).offset().top-1.15*navHeight else 0
  }, 300, cb

$('a.Nav--link').not('.Nav--noScroll').on 'click', (event) ->
  event.stopPropagation()
  event.preventDefault()
  a = $ @
  p =  a.parent()
  unless p.hasClass 'disabled'
    link = a.attr('href').split('#')[1]
    if link then link = '#'+link
    # restart if the link was empty
    scrollTo link, (unless link then restart)
