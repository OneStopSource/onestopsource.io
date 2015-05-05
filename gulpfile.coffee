'use strict'

Destination       = 'build'
DestinationStatic = 'build/static'

gulp = require 'gulp'
jade = require 'gulp-jade'

browserSync = require('browser-sync').create()
reload      = browserSync.reload


gulp.task 'html', ->
  gulp.src 'jade/**/*.jade'
  .pipe jade pretty: true
  .pipe gulp.dest Destination


gulp.task 'serve', ->
    browserSync.init
      server:
        baseDir: Destination

    gulp.watch 'jade/**/*.jade', ['reload:jade']

gulp.task 'reload:jade', ['html'], reload

gulp.task 'build', ['html']
gulp.task 'default', ['build', 'serve']
