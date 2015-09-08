browserSync = require 'browser-sync'
coffee      = require 'gulp-coffee'
gulp        = require 'gulp'
gutil       = require 'gulp-util'
sass        = require 'gulp-sass'
uglify      = require 'gulp-uglify'

# COMPILE

gulp.task 'compile:sass', ->
  gulp.src 'glitchtop.sass'
    .pipe sass outputStyle: 'compressed'
    .pipe gulp.dest './'

gulp.task 'compile:coffee', ->
  gulp.src '*.coffee'
    .pipe coffee bare: true
    .on 'error', gutil.log
    .pipe gulp.dest './'

# SERVE

gulp.task 'serve', ->
  browserSync.init
    open: false
    browser: 'google chrome'
    server: 
      baseDir: './'
    files: [
      '*.html'
      '*.css'
      '*.js'
    ]

  gulp.watch '*.coffee', ['compile:coffee']
  gulp.watch '*.sass', ['compile:sass']
  gulp.watch 'app.js', browserSync.reload

# DEFAULT

gulp.task 'default', ['serve']
