# main svgerber site application
# svgerber.cousins.io

# requires jquery, backbone, and lodash

# btoa polyfill
Base64 = require 'Base64'
unless typeof window.btoa is 'function' then window.btoa = Base64.btoa
unless typeof window.atob is 'function' then window.atob = Base64.atob

# TODO: webworker polyfill? will need to do something for IE9 support

# load the backbone application view to start the app
AppView = require './views/app'
appView = new AppView()
# start the router
Router = require './routers/router'
router = new Router()
Backbone.history.start()
