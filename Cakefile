# cakefile for svgerber
# This cakefile supports automatic dependency resolution by sticking:
  #require "filename"
# in any file that depends on another file.

# Cakefile options
# valid build environments (first value is default)
envs = [
  'dev'          # development environment (default)
  'production'  # production environment
]
env = null

# coffeescript
# main project file
main = 'coffee/app.coffee'
# coffeescript directory to watch
coffeeDir = 'coffee'
# output bundle file
bundle = 'app.js'
# compiler options
browserifyOpts = {
  'dev': '--debug'
  'production': ''
}

# uglify.js
uglyOpts = "--preamble '/* view source at github.com/mcous/svgerber */'
            --compress drop_console=true
            --mangle
            --output #{bundle}"

# jade
jadeDir = 'jade'
# output directory
jadeOut = '.'
# includes directory
jadeIncludes = 'jade-includes'
# compiler options
jadeOpts = {
  'all': "--out #{jadeOut}"
  'dev': '--pretty'
  'production': ''
}

# stylus
stylusDir = 'stylus'
stylusOut = '.'
stylusOpts = {
  'all': "--out #{stylusOut} --include-css"
  'dev': ''
  'production': '--compress'
}

# simple dev server with node-static
port = 8080

# dependencies
# gonna need fs to read the files and exec to do stuff
fs = require 'fs'
{exec} = require 'child_process'
# also use node static as a basic webserver
stat = require 'node-static'


# Cakefile options
option '-e', '--environment [ENV_NAME]', 'set the build environment (dev or production)'

# Cakefile tasks
# build jade
task 'build:jade', 'compile jade index to html', (options) ->
  # build the environment
  env = options.environment ? envs[0]
  if env in envs is -1 then throw "#{env} is not a valid environment (dev or production)"

  # compile the jade
  console.log "compiling jade to html"
  exec "jade #{jadeOpts.all} #{jadeOpts[env]} #{jadeDir}/*", (error, stdout, stderr) ->
    if error then throw error
    console.log "...done compiling jade"
    console.log stdout + stderr

# build stylus
task 'build:stylus', 'compile stylus files into css', (options) ->
  # build the environment
  env = options.environment ? envs[0]
  if env in envs is -1 then throw "#{env} is not a valid environment (dev or production)"

  # compile the stylus
  console.log "compiling stylus to css"
  exec "stylus #{stylusOpts.all} #{stylusOpts[env]} #{stylusDir}/*", (error, stdout, stderr) ->
    if error then throw error
    console.log "...done compiling stylus"
    console.log stdout + stderr

# build coffee
task 'build:coffee', 'compile coffee files into javascript', (options) ->
  env = options.environment ? envs[0]
  if env in envs is -1 then throw "#{env} is not a valid environment (dev or production)"

  exec "browserify #{browserifyOpts[env]} #{main} > #{bundle}", (error, stdout, stderr) ->
    if error then throw error
    console.log "...done compiling coffee"
    console.log stdout + stderr
    if env is 'production'
      console.log "compressing #{bundle}"
      exec "uglifyjs #{bundle} #{uglyOpts}", (error, stdout, stderr) ->
        if error then throw error
        console.log "...done compressing #{bundle}"
        console.log stdout + stderr

# build all
task 'build', 'compile coffee, jade, and stylus', (options) ->
  # build the coffee
  invoke 'build:coffee'
  # build the jade
  invoke 'build:jade'
  # and the stylus
  invoke 'build:stylus'

# watch task
task 'watch', 'watch coffeescript and jade files for changes', (options) ->
  # run the first build
  invoke 'build'

  # watch coffeescript files
  fs.watch(coffeeDir, (event, filename) ->
    console.log "#{filename} was #{event}d; rebuilding"
    invoke 'build:coffee'
  )

  # watch jade files
  fs.watch(jadeDir, (event, filename) ->
    console.log "#{filename} was #{event}d; rebuilding #{filename[..-6]}.html"
    invoke 'build:jade'
  )

  # watch stylus files
  fs.watch(stylusDir, (event, filename) ->
    console.log "#{filename} was #{event}d; rebuilding #{filename[..-6]}.css"
    invoke 'build:stylus'
  )

# serve task
task 'serve', "watch and serve the files to localhost:#{port}", (options) ->
  invoke 'watch'
  # start up a dev server
  devServer = new stat.Server '.'
  require('http').createServer( (request, response) ->
    request.addListener( 'end', ->
      devServer.serve(request, response, (error, result)->
        if error then console.log "error serving #{request.url}"
        else console.log "served #{request.url}"
      )
    ).resume()
  ).listen port
  console.log "server started at http://localhost:#{port}\n"
