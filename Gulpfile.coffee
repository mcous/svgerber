# gulpfile
# front end deps
jeet       = require 'jeet'
rupture    = require 'rupture'
# dependencies
browserify = require 'browserify'
watchify   = require 'watchify'
source     = require 'vinyl-source-stream'
path       = require 'path'
del        = require 'del'
# gulp and plugins
gulp       = require 'gulp'
gutil      = require 'gulp-util'
streamify  = require 'gulp-streamify'
stylus     = require 'gulp-stylus'
prefix     = require 'gulp-autoprefixer'
minifycss  = require 'gulp-minify-css'
jade       = require 'gulp-jade'
uglify     = require 'gulp-uglify'
deploy     = require 'gulp-gh-pages'
ignore     = require 'gulp-ignore'
concat     = require 'gulp-concat'
rename     = require 'gulp-rename'
webserver  = require 'gulp-webserver'

# deploy location
DEPLOY = './public'

# samples location
SAMPLES = './samples'

# app files
SCRIPT   = './src/index.coffee'
TEMPLATE = './templates/index.jade'
STYLE    = './styles/index.styl'

# vendor files
VENDOR_JS = [
  './node_modules/jquery/dist/jquery.min.js'
  './node_modules/lodash/index.js'
  './node_modules/backbone/backbone-min.js'
]
VENDOR_CSS = [
  './mode_modules/octicons/octicons/octicons.css'
]
VENDOR_ICON = [
  './node_modules/octicons/octicons/octicons.eot'
  './node_modules/octicons/octicons/octicons.ttf'
  './node_modules/octicons/octicons/octicons.woff'
  './node_modules/octicons/octicons/octicons.svg'
]

# files to deploy
DEPLOY_FILES = [
  "#{DEPLOY}/*"
  'CNAME'
]

# arguments (checks for production build)
argv = require('minimist') process.argv.slice(2), {
  default: { p: false }
  alias: { p: 'production' }
}

# bundle vendor files with concat if necessary and copy them to deploy folder
gulp.task 'vendorCSS', ->
  gulp.src VENDOR_CSS
    .pipe concat 'vendor.css'
    .pipe gulp.dest DEPLOY
gulp.task 'vendorJS', ->
  gulp.src VENDOR_JS
    .pipe concat 'vendor.js'
    .pipe gulp.dest DEPLOY
gulp.task 'vendorIcon', ->
  gulp.src VENDOR_ICON
    .pipe gulp.dest DEPLOY
gulp.task 'vendor', [ 'vendorCSS', 'vendorJS', 'vendorIcon' ]

# copy samples folder to the deploy folder
gulp.task 'samples', ->
  gulp.src "#{SAMPLES}/*"
    .pipe gulp.dest DEPLOY

# clean out the deploy folder
gulp.task 'clean', (done) ->
  del "#{DEPLOY}/*", done

# compile stylus
gulp.task 'style', ->
  gulp.src STYLE
    .pipe stylus( { use: [ jeet(), rupture() ] } ).on 'error', gutil.log
    .pipe prefix '> 1%', 'last 3 versions', 'Firefox ESR', 'Opera 12.1'
    .pipe if argv.p then minifycss() else gutil.noop()
    .pipe rename 'app.css'
    .pipe gulp.dest DEPLOY

# compile jade
gulp.task 'template', ->
  gulp.src TEMPLATE
    .pipe jade().on 'error', gutil.log
    .pipe gulp.dest DEPLOY

# default task build everything
gulp.task 'build', [ 'vendor', 'samples', 'style', 'template', 'script' ]

# set watch mode
gulp.task 'watch', ->
  global.watching = true
  # watch stylus
  gulp.watch './styles/*.styl', [ 'style' ]
  # watch jade
  gulp.watch './templates/*.jade', [ 'template' ]

# watch files with coffee files with watchify and others with gulp.watch
gulp.task 'script', (done) ->
  bundler = browserify {
    entries: [ SCRIPT ]
    extensions: [ '.coffee' ]
    debug: !argv.production
    # watchify required options
    cache: {}, packageCache: {}, fullPaths: true
  }
  rebundle = ->
    bundler.bundle()
      .on 'error', (e) ->
        gutil.log 'browserify error', e
      .pipe source 'app.js'
      .pipe if argv.p then streamify uglify {
        preamble: '/* view source at github.com/mcous/svgerber */'
        compress: { drop_console: true }
        mangle: true
      } else gutil.noop()
      .pipe gulp.dest DEPLOY
  # log when necessary
  bundler.on 'log', (msg) -> gutil.log "bundle: #{msg}"
  # watch if watching
  if global.watching
    bundler = watchify bundler
    bundler.on 'update', rebundle
  # bundle coffee
  rebundle()

# deploy to gh-pages
gulp.task 'deploy', [ 'build' ], ->
  gulp.src DEPLOY_FILES
    .pipe deploy {
      branch: if argv.p then 'gh-pages' else 'test-deploy'
      push: argv.p
    }

# dev server is default task
gulp.task 'default', [ 'watch', 'build' ], ->
  gulp.src DEPLOY
    .pipe webserver {
      host: '0.0.0.0'
      livereload: true
      open: true
    }
