# cakefile for svgerber
#
# This cakefile supports automatic dependency resolution by sticking:

  #require "filename"

# in any file that depends on another file.
#
# coffeescript files will be concatinated into one javascript file

# coffeescript
# main project file
main = 'app.coffee'
# coffeescript source directory
input = 'coffee'
# output file
output = 'app.js'
# compiler options
opts = '--map'

# jade
# input files
jadein = 'jade/index.jade'
# output directories
jadeout = '.'

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
requireMatch = /^#require\s+(('[\w\.]+')|("[\w\.]+"))\s*$/

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
      deps[i] = d.match(/('[\w\.]+')|("[\w\.]+")/)[0]
      deps[i] = deps[i][1..-2]
      # lets find that file
      if fs.existsSync(input+'/'+deps[i])
        @depList.push input+'/'+deps[i]
      else if fs.existsSync(input+'/'+deps[i]+'.coffee')
        @depList.push input+'/'+deps[i]+'.coffee'
      else if fs.existsSync(input+'/'+deps[i]+'.litcoffee')
        @depList.push input+'/'+deps[i]+'.litcoffee'
      else
        throw "UnableToFind_#{deps[i]}_Error"

# build the file node list recursively
nodes = []
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

# Cakefile tasks
# build jade
task 'jade', 'compile jade index to html', (options) ->
  console.log "compiling #{jadein}\n"
  exec "jade #{jadein} --out #{jadeout}"

# watch task
task 'watch', 'watch coffeescript and jade files for changes', (options) ->
  # do a build to get our dependency graph and html
  invoke 'build'

  # watch all the coffeescript files
  for n in nodes
    do (n) ->
      fs.watchFile n.file, (now, old) ->
        console.log "#{n.file} changed. rebuilding"
        invoke 'build' if +now.mtime isnt +old.mtime

  for j in jadein.split ' '
    do (j) ->
      fs.watchFile j, (now, old) ->
        console.log "#{j} changed. rebuilding"
        invoke 'jade' if +now.mtime isnt +old.mtime

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
  console.log "server started at http://localhost:#{port}\n"

# build task
task 'build', 'resolve dependencies and build the app', (options) ->
  # gather all the children of the main app
  console.log "gathering dependencies of #{main}"
  nodes = []
  gatherChildren input+'/'+main

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
  for n in nodes
    fileList += n.file + ' '
  console.log "files found: #{fileList}"

  # compile the coffee script
  console.log "compiling #{output}\n"
  exec "coffee #{opts} --join #{output} --compile #{fileList}"

  # compile the jade
  invoke 'jade'
