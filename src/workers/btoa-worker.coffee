# webworker to encode SVGs for download

# btoa polyfill
Base64 = require 'Base64'
unless typeof self.btoa is 'function' then self.btoa = Base64.btoa

# listen for a posted message and respond with base64 encoded data
self.addEventListener 'message', (e) ->
  string = e.data.string
  name = e.data.name
  self.postMessage { name: name, string: btoa string }
