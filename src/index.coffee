# main svgerber site application
# svgerber.cousins.io

# requires jquery, backbone, and lodash

# btoa polyfill
Base64 = require 'Base64'
unless typeof window.btoa is 'function' then window.btoa = Base64.btoa
unless typeof window.atob is 'function' then window.atob = Base64.atob

# TODO: webworker polyfill? will need to do something for IE9 support
# check browser support, and attach error message to dom if necessary
# check for svg support
if typeof document.createElement('svg').getAttributeNS is 'undefined' or
# check for web worker support
typeof Worker is 'undefined' or typeof FileReader is 'undefined'
  unsupported = new (require './views/unsupported-view')()
  $('body').append unsupported.render().el

# load the backbone application view to start the app
AppView = require './views/app-view'
appView = new AppView()
# start the router
Router = require './routers/router'
router = new Router()
Backbone.history.start()
