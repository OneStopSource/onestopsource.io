[BrowserSync]: http://www.browsersync.io/
[Jade]: http://jade-lang.com
[Sass]: http://sass-lang.com

    'use strict'

OneStopSource.io gulp file
==========================

- HTML is preprocessed using [Jade][]
- CSS is preprocesses using [Sass][]
- [BrowserSync][] is used for development server

Configuration:

    Debug = false

Build destinations -- whole website is static build from jade templates
and static files are inside `static` directory.

    Destination       = 'build'
    DestinationStatic = 'build/static'

Dependencies
------------

Core:

    gulp = require 'gulp'
    ifElse = require 'gulp-if-else'

Languages and processors:

    jade = require 'gulp-jade'
    sass = require 'gulp-sass'

Optimalization and compression:

    minifyHtml = require 'gulp-minify-html'
    minifyCss = require 'gulp-minify-css'
    lazypipe = require 'lazypipe'
    bytediff = require 'gulp-bytediff'
    sourcemaps = require 'gulp-sourcemaps'

Style checkers:

    coffeelint = require 'gulp-coffeelint'

Load [BrowserSync][] for serving static files, automatic
reloading and synchronization of multiple browsers:

    browserSync = require('browser-sync').create()
    reload      = browserSync.reload

Publish static assets to AWS S3 bucket and load AWS IAM credentials:

    s3 = require 'gulp-s3'
    fs = require 'fs'

Helpers
-------

Pipe factory for minifying files which outputs the size difference of minified
files.

Usage: `.pipe minify minifyCss`

    minify = (func) ->
      lazypipe()
      .pipe bytediff.start
      .pipe func
      .pipe bytediff.stop

Tasks
-----

The **default** task builds all static assets, runs local server at :3000
and watches for changes. Use **build** task for one-time build.

    gulp.task 'build', ['html', 'css', 'files']
    gulp.task 'default', ['serve']

**debug-mode** -- Enables debug mode: Minification is disabled, source maps are
created and gulp doesn't exit on errors

    gulp.task 'debug-mode', ->
      Debug = true

**publish** -- Publish static assets to S3
(deploy to <http://onestopsource.io>).

    gulp.task 'publish', ['build'], ->
      awsCredentials = JSON.parse fs.readFileSync './aws.json'

      options =
        headers:
          'Cache-Control': 'max-age=86400, no-transform, public'

      gulp.src Destination + '/**'
      .pipe s3 awsCredentials, options

**html** -- Compile [Jade][] templates.

    gulp.task 'html', ->
      options =
        pretty: false
        locals:
          debug: Debug

      gulp.src 'jade/**/*.jade'
      .pipe jade options
      .pipe ifElse !Debug, minify minifyHtml
      .pipe gulp.dest Destination
      .pipe reload stream: true

*css* -- Compile [Sass][] files to CSS. Include source maps in debug mode.

    gulp.task 'css', ->
      gulp.src 'scss/onestopsource.scss'
      .pipe ifElse Debug, sourcemaps.init
      .pipe sass()
      .pipe ifElse Debug, sourcemaps.write, minify minifyCss
      .pipe gulp.dest DestinationStatic + '/css'
      .pipe reload stream: true

**files** -- Copy static files

    gulp.task 'files', ->
      gulp.src 'files/**'
      .pipe gulp.dest Destination


**serve** -- Start serving static files and watch for file changes.

    gulp.task 'serve', ['debug-mode', 'build'], ->
      browserSync.init
        server:
          baseDir: Destination

      gulp.watch 'jade/**/*.jade', ['html']
      gulp.watch 'scss/**/*.scss', ['css']
      gulp.watch 'files/**', ['files']

**ci** -- Run tests and code checks

    gulp.task 'ci', ['lint:coffee']

**lint:coffee** -- Check coffeescripts for coding style violations

    gulp.task 'lint:coffee', ->
      gulp.src [
        'gulpfile.litcoffee'
      ]
      .pipe coffeelint()
      .pipe coffeelint.reporter()
      .pipe coffeelint.reporter 'fail'
