browserSync = require 'browser-sync'
coffee      = require 'gulp-coffee'
gulp        = require 'gulp'
gutil       = require 'gulp-util'
sass        = require 'gulp-sass'
uglify      = require 'gulp-uglify'

# COMPILE

gulp.task 'compile:sass', ->
  gulp.src '*.sass'
    .pipe sass outputStyle: 'expanded'
    .pipe gulp.dest './'

gulp.task 'compile:coffee', ->
  gulp.src 'app.coffee'
    .pipe coffee bare: true
    .on 'error', gutil.log
    .pipe gulp.dest './'

gulp.task 'compile:all', ['compile:sass', 'compile:coffee']

# SERVE

gulp.task 'serve', ['compile:all'], ->
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

  gulp.watch 'app.coffee', ['compile:coffee']
  gulp.watch 'app.js', browserSync.reload

# DEFAULT

gulp.task 'default', ['serve']
