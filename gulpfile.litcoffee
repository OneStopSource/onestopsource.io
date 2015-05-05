[BrowserSync]: http://www.browsersync.io/
[Jade]: http://jade-lang.com

    'use strict'

OneStopSource.io gulp file
==========================

- HTML is preprocessed using [Jade][]
- CSS is postprocesses using `PostCSS`
- [BrowserSync][] is used for development server


Define build destinations -- whole website is static build from jade templates
and static files are inside `static` directory.

    Destination       = 'build'
    DestinationStatic = 'build/static'

Dependencies
------------

    gulp = require 'gulp'
    jade = require 'gulp-jade'

Load [BrowserSync][] for serving static files, automatic
reloading and synchronization of multiple browsers:

    browserSync = require('browser-sync').create()
    reload      = browserSync.reload

Tasks
-----

The **default** task builds all static assets, runs local server at :3000
and watches for changes. Use **build** task for one-time build.

    gulp.task 'build', ['html']
    gulp.task 'default', ['build', 'serve']

**html** -- Compile [Jade][] templates.

    gulp.task 'html', ->
      gulp.src 'jade/**/*.jade'
      .pipe jade pretty: true
      .pipe gulp.dest Destination

**serve** -- Start serving static files and watch for file changes.

    gulp.task 'serve', ->
        browserSync.init
          server:
            baseDir: Destination
        gulp.watch 'jade/**/*.jade', ['reload:jade']

**reload:jade** -- Reload browser after new html is compiled.

    gulp.task 'reload:jade', ['html'], reload
