# cakefile for svgerber
#
# This cakefile supports automatic dependency resolution by sticking:

  #require "filename"

# in any file that depends on another file.
#
# coffeescript files will be concatinated into one javascript file

# Cakefile options
# valid build environments (first value is default)
envs = [
  'dev'          # development environment (default)
  'productions'  # production environment
]
env = null

# coffeescript
# main project file
main = 'app.coffee'
# coffeescript source directory
coffeeDir = 'coffee'
# intermediate js output directory
jsDir = 'js'
# compiler options
coffeeOpts = {
  'dev': '--map'
  'production': ''
}
# dependency resolution
nodes = []
jsList = ''

# uglify.js
uglyOpts = ''
# output bundle file
bundle = 'app.js'

# jade
jadeDir = 'jade'
# output directory
jadeOut = '.'
# includes directory
jadeIncludes = 'jade-includes'
# compiler options
jadeOpts = {
  'dev': '--pretty'
  'production': ''
}

# simple dev server with node-static
port = 8080

# dependencies
# gonna need fs to read the files and exec to do stuff
fs = require 'fs'
{exec} = require 'child_process'
# also use node static as a basic webserver
stat = require 'node-static'

# constants
# match for the require call
requireMatch = /^#require\s+(('[\w\.\/]+')|("[\w\.\/]+"))\s*$/

# dependency node class to build out the graph
class Node
  constructor: (@file, parent=null) ->
    @parents = []
    @children = []
    @depList = []
    if parent? then @parents.push parent
    @getDepList()

  # add a child (dependency)
  addChild: (child) ->
    if child?
      if @children.indexOf child is -1 then @children.push child

  # add a parent (file that depends on this file)
  addParent: (parent) ->
    if parent?
      if @parents.indexOf parent is -1 then @parents.push parent

  # requirsively traverse the parents to the top of the graph
  traverseParents: (start=@) ->
    level = 0
    for p in @parents
      # if the file depends on itself in some way, that is bad
      if p is start then throw "CircularDependencyError"
      # else, recurse to count the levels
      height = 1 + p.traverseParents(start)
      level = height if height > level
    # return the greatest distance between this node and the top
    level

  # parse the file to get its dependecy list (called in constructor)
  getDepList: ->
    deps = []
    lines = fs.readFileSync(@file, 'UTF-8')
    lines = lines.split '\n'
    # gather the lines that call out dependencies
    for line in lines
      if line.match requireMatch then deps.push line
    # format them into their full filenames
    for d,i in deps
      # strip away the require stuff
      deps[i] = d.match(/('[\w\.\/]+')|("[\w\.\/]+")/)[0]
      deps[i] = deps[i][1..-2]
      # lets find that file
      if fs.existsSync(deps[i])
        @depList.push deps[i]
      else if fs.existsSync(coffeeDir+'/'+deps[i])
        @depList.push coffeeDir+'/'+deps[i]
      else if fs.existsSync(coffeeDir+'/'+deps[i]+'.coffee')
        @depList.push coffeeDir+'/'+deps[i]+'.coffee'
      else if fs.existsSync(coffeeDir+'/'+deps[i]+'.litcoffee')
        @depList.push coffeeDir+'/'+deps[i]+'.litcoffee'
      else
        throw "UnableToFind_#{deps[i]}_Error"

# build the file node list recursively
gatherChildren = (file, parent=null) ->
  # check to see if the file has already got a node
  nodeExists = false
  for n in nodes
    # if it does, grab it, add to its parents, and break the loop
    if n.file is file
      nodeExists = true
      node = n
      node.addParent parent
      break

  # if it's a new node, create it and push it to the node list
  unless nodeExists
    node = new Node(file, parent)
    nodes.push node

  # call gatherChildren on the dependencies
  for f in node.depList
    depNode = gatherChildren(f, node)
    node.addChild depNode

  # return the node for recursability
  node


# Cakefile options
option '-e', '--environment [ENV_NAME]', 'set the build environment (dev or production)'

# build the environment
task 'build:environment', (options) ->
  env = options.environment ? envs[0]
  if env in envs is -1 then throw "#{env} is not a valid environment (dev or production)"
  console.log "env set to #{env}"
invoke 'build:environment'


# Cakefile tasks
# build jade
task 'build:jade', 'compile jade index to html', (options) ->
  # get our list of scripts
  scripts = ''
  if nodes.length is 0 then throw 'coffeeNotCompiledError'

  if env is 'dev'
    for j in jsList.split ' '
      if j.length isnt 0 then scripts += "script(src='#{j}')\n"
  else if env is 'production'
    scripts = "script(src='#{bundle}')\n"

  # write the scripts.jade file
  console.log "building jade include for scripts for #{env}"
  fs.mkdir(jadeIncludes, (error) ->
    fs.writeFile("#{jadeIncludes}/scripts.jade", scripts, (error) ->
      if error then throw error
      console.log "#{jadeIncludes}/scripts.jade written; make sure it is included in the necessary jade files"

      # compile the jade
      console.log "compiling jade to html"
      exec "jade #{jadeOpts[env]} --out #{jadeOut} #{jadeDir}/*", (error, stdout, stderr) ->
        if error then throw error
        console.log "...done compiling jade"
        console.log stdout + stderr
    )
  )

# watch task
task 'watch', 'watch coffeescript and jade files for changes', (options) ->
  # do a build to get our dependency graph and html
  invoke 'build'

  # watch coffeescript files
  fs.watch(coffeeDir, (event, filename) ->
    console.log "#{filename} was #{event}d; rebuilding"
    invoke 'build'
  )

  # watch jade files
  fs.watch(jadeDir, (event, filename) ->
    console.log "#{filename} was #{event}d; rebuilding #{filename[..-6]}.html"
    invoke 'build'
  )


# serve task
task 'serve', 'watch and serve the files to localhost:8080', (options) ->
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

task 'build', 'resolve coffee dependencies, compile coffee, and compile jade', (options) ->
  # gather all the children of the main app
  console.log "gathering dependencies of #{main}"
  nodes = []
  gatherChildren coffeeDir+'/'+main

  # sort the files be tree depth
  nodes.sort( (a,b) ->
    aDepth = a.traverseParents()
    bDepth = b.traverseParents()
    if aDepth < bDepth then 1
    else if aDepth > bDepth then -1
    else 0
  )

  # create a list of files in order
  fileList = ''
  jsList = ''
  coffeeList = ''
  for n in nodes
    f = n.file
    fileList += f + ' '
    # check if the file is coffee
    if f.match /^.+\.(lit)?coffee$/
      # add it to the coffee list
      coffeeList += f + ' '
      # strip out coffee extension and dir and replace with js
      f = f[coffeeDir.length..]
      f = f.match /.*(?=((lit)?coffee$))/
      f = jsDir + f[0] + 'js'
    # push the files to the js list
    jsList += f + ' '
  console.log "files found: #{fileList}"

  # it is now fine to build the jade
  invoke 'build:jade'

  # compile the coffee script
  console.log "compiling coffeescript"
  exec "coffee #{coffeeOpts[env]} --output #{jsDir} --compile #{coffeeList}", (error, stdout, stderr) ->
    if error then throw error

    console.log "...done compiling coffee"
    console.log stdout + stderr

    # if the dev is production, bundle the js
    if env is 'production' then invoke 'build:bundle'

task 'build:bundle', 'bundle all the js files together', (options) ->
  # throw an error if coffee wasn't built beforehand
  if jsList.length is 0 then throw 'CoffeeNotCompiledError'

  # concatinate the js files
  console.log "concatinating javascript files..."
  exec "uglifyjs #{jsList} --verbose --output #{bundle}", (error, stdout, stderr) ->
    if error then throw error
    console.log "...done concatinating"
    console.log stdout + stderr
