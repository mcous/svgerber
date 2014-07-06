# gulpfile
# dependencies
browserify = require 'browserify'
source     = require 'vinyl-source-stream'

# plugins
gulp       = require 'gulp'
stylus     = require 'gulp-stylus'
prefix     = require 'gulp-autoprefixer'
minifycss  = require 'gulp-minify-css'
jade       = require 'gulp-jade'
uglify     = require 'gulp-uglify'
#livereload = require 'gulp-livereload'
notify     = require 'gulp-notify'
rimraf     = require 'gulp-rimraf'

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
    .pipe minifycss()
    .pipe gulp.dest '.'
    .pipe notify { message: 'stylus task complete' }

# compile jade
gulp.task 'jade', ->
  gulp.src './jade/index.jade'
    .pipe jade {
      pretty: !argv.p
    }
    .pipe gulp.dest '.'
    .pipe notify { message: 'jade task complete' }

# concatinate third-part js files
#gulp.task 'vendor' ->


# compile and bundle coffee with browserify
gulp.task 'coffee', ->
  browserify './coffee/app.coffee'
    .bundle {
      insertGlobals: !argv.p
      debug: !argv.p
    }
    .pipe source 'app.js'
    .pipe gulp.dest '.'
    .pipe notify { message: 'coffee task complete' }

# build everything
gulp.task 'build', ->
  gulp.start 'stylus', 'jade', 'coffee'

# default task (build everything)
gulp.task 'default', ->
