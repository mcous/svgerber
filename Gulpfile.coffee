# gulpfile
# dependencies
browserify = require 'browserify'
source     = require 'vinyl-source-stream'
stat = require 'node-static'
# plugins
gulp       = require 'gulp'
gutil      = require 'gulp-util'
streamify  = require 'gulp-streamify'
stylus     = require 'gulp-stylus'
prefix     = require 'gulp-autoprefixer'
minifycss  = require 'gulp-minify-css'
jade       = require 'gulp-jade'
uglify     = require 'gulp-uglifyjs'
livereload = require 'gulp-livereload'
rimraf     = require 'gulp-rimraf'
deploy     = require 'gulp-gh-pages'

# arguments (checks for production build)
argv = require('minimist') process.argv.slice(2), {
  default: {
    p: false
  }
  alias: {
    p: 'production'
  }
}

# clean
gulp.task 'clean', ->
  gulp.src ['./app.css', './app.js', './index.html'], {read: false}
    .pipe rimraf()

# compile stylus
gulp.task 'stylus', ->
  gulp.src './stylus/app.styl'
    .pipe stylus {
      'include css': 'true'
    }
    .pipe prefix 'last 2 versions', '> 5%'
    .pipe if argv.p then minifycss() else gutil.noop()
    .pipe gulp.dest '.'

# compile jade
gulp.task 'jade', ->
  gulp.src './jade/index.jade'
    .pipe jade {
      pretty: !argv.p
    }
    .pipe gulp.dest '.'

# default task (build everything)
gulp.task 'default', ['clean'], ->
  gulp.start 'stylus', 'jade', 'coffee'

# watch files with autoreload
gulp.task 'watch', ->
  # initial build
  gulp.start 'default'

  # live reload server
  server = livereload

  # watch stylus
  gulp.watch './stylus/*.styl', ['stylus']
  # watch jade
  gulp.watch './jade/*.jade', ['jade']
  # watch coffee
  gulp.watch './coffee/*.coffee', ['coffee']

  # reload on changes
  gulp.watch ['./index.html', './app.css', './app.js']
    .on 'change', (file) ->
      server.changed file.path

# set up static server
gulp.task 'serve', ->
  server = new stat.Server '.'
  require('http').createServer( (request, response) ->
    request.addListener( 'end', ->
      server.serve(request, response, (error, result)->
        if error then console.log "error serving #{request.url}"
        else console.log "served #{request.url}"
      )
    ).resume()
  ).listen 8080
  console.log "server started at http://localhost:8080\n"

  gulp.start 'watch'

# deploy to gh-pages
gulp.task 'deploy', ->
  gulp.src './'
    .pipe deploy {
      push: false
    }
