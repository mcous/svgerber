# gulpfile
# dependencies
browserify = require 'browserify'
watchify   = require 'watchify'
source     = require 'vinyl-source-stream'
stat       = require 'node-static'
# plugins
gulp       = require 'gulp'
util       = require 'gulp-util'
streamify  = require 'gulp-streamify'
stylus     = require 'gulp-stylus'
prefix     = require 'gulp-autoprefixer'
minifycss  = require 'gulp-minify-css'
jade       = require 'gulp-jade'
uglify     = require 'gulp-uglifyjs'
livereload = require 'gulp-livereload'
rimraf     = require 'gulp-rimraf'
deploy     = require 'gulp-gh-pages'
ignore     = require 'gulp-ignore'
concat     = require 'gulp-concat'

# deploy files
deployFiles = [
  'index.html'
  'app.css'
  'vendor.js'
  'app.js'
  'octicons.eot'
  'octicons.svg'
  'octicons.ttf'
  'octicons.woff'
  'LICENSE.md'
  'README.md'
  'CNAME'
]

# vendor files
vendorFiles = [
  './bower_components/jquery/dist/jquery.min.js'
  './bower_components/bootstrap/dist/js/bootstrap.min.js'
]

# arguments (checks for production build)
argv = require('minimist') process.argv.slice(2), {
  default: { p: false }
  alias: { p: 'production' }
}

# octicon stuff
gulp.task 'octicons', ->
  gulp.src './bower_components/octicons/octicons/octicons.*'
    .pipe ignore.include /(\.eot)|(\.svg)|(\.ttf)|(\.woff)/
    .pipe gulp.dest '.'

# clean tasks
gulp.task 'clean', ['clean:css', 'clean:js', 'clean:html']

gulp.task 'clean:css', ->
  gulp.src '*.css', {read: false}
    .pipe rimraf()

gulp.task 'clean:js', ->
  gulp.src 'app.js', {read: false}
    .pipe rimraf()

gulp.task 'clean:html', ->
  gulp.src '*.html', {read: false}
    .pipe rimraf()

# compile stylus
gulp.task 'stylus', ['clean:css', 'octicons'], ->
  gulp.src './stylus/app.styl'
    .pipe stylus {
      'include css': 'true'
    }
    .pipe prefix 'last 2 versions', '> 5%'
    .pipe if argv.p then minifycss() else util.noop()
    .pipe gulp.dest '.'

# compile jade
gulp.task 'jade', ['clean:html'], ->
  gulp.src './jade/index.jade'
    .pipe jade {
      pretty: !argv.p
    }
    .pipe gulp.dest '.'

# bundle vendor files with concat
gulp.task 'vendor', ->
  gulp.src vendorFiles
    .pipe concat 'vendor.js'
    .pipe gulp.dest '.'

# compile and bundle coffee with browserify
gulp.task 'coffee', ['clean:js'], ->
  browserify './coffee/app.coffee', {
      insertGlobals: !argv.p
      debug: !argv.p
    }
    .bundle()
    .pipe source 'app.js'
    .pipe if argv.p then streamify uglify {
      preamble: '/* view source at github.com/mcous/svgerber */'
      compress: { drop_console: true }
      mangle: true
    } else util.noop()
    .pipe gulp.dest '.'

# default task (build everything)
gulp.task 'default', ['stylus', 'jade', 'coffee']

# watch files with autoreload
gulp.task 'watch', ['default'], ->
  bundler = watchify browserify './coffee/app.coffee', {
    insertGlobals: !argv.p
    debug: !argv.p
    cache: {}
    packageCache: {}
    fullPaths: {}
  }
  rebundle = ->
    bundler.bundle()
      .on 'error', (e) ->
        util.log 'browserify error', e
      .pipe source 'app.js'
      .pipe gulp.dest '.'
  bundler.on 'update', rebundle
  bundler.on 'log', (msg) -> util.log "bundle: #{msg}"

  # watch stylus
  gulp.watch './stylus/*.styl', ['stylus']
  # watch jade
  gulp.watch './jade/*.jade', ['jade']
  # bundle coffee
  rebundle()

# set up static server with autoreload
gulp.task 'serve', ['watch'], ->
  server = new stat.Server '.'
  require('http').createServer( (request, response) ->
    request.addListener( 'end', ->
      server.serve(request, response, (error, result)->
        if error then util.log "error serving #{request.url}"
        else util.log "served #{request.url}"
      )
    ).resume()
  ).listen 8080
  util.log "server started at http://localhost:8080\n"

  # live reload server
  livereload.listen()
  # reload on changes
  gulp.watch ['./index.html', './app.css', './app.js']
    .on 'change', (file) ->
      livereload.changed file.path

# deploy to gh-pages
gulp.task 'deploy', ['default'], ->
  gulp.src deployFiles
    .pipe deploy {
      branch: 'gh-pages'
      push: argv.p
    }
