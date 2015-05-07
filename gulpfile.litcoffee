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

    BuildRoot = 'build'

    Destination =
      all: BuildRoot + '/**'
      html: BuildRoot
      css: BuildRoot + '/static/css'

    Source =
      jade: 'jade/**/*.jade'
      scss: 'scss/**/*.scss'
      files: 'files/**'

Dependencies
------------

Core:

    gulp = require 'gulp'
    ifElse = require 'gulp-if-else'

Languages and compilers:

    jade = require 'gulp-jade'
    sass = require 'gulp-sass'
    autoprefixer = require 'gulp-autoprefixer'

Optimization and compression:

    minifyHtml = require 'gulp-minify-html'
    minifyCss = require 'gulp-minify-css'
    lazypipe = require 'lazypipe'
    bytediff = require 'gulp-bytediff'
    sourcemaps = require 'gulp-sourcemaps'

Style checkers:

    coffeelint = require 'gulp-coffeelint'

[BrowserSync][] development server:

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

      gulp.src Destination.all
      .pipe s3 awsCredentials, options

**html** -- Compile [Jade][] templates.

    gulp.task 'html', ->
      options =
        pretty: false
        locals:
          debug: Debug

      gulp.src Source.jade
      .pipe jade options
      .pipe ifElse !Debug, minify minifyHtml
      .pipe gulp.dest Destination.html
      .pipe reload stream: true

*css* -- Compile [Sass][] files to CSS. Include source maps in debug mode.
Note: You *really* need to generate sourcemaps twice. There's a bug in
gulp-sass, gulp-autprefixer or gulp-sourcemaps (dunno which one). See
[issue](https://github.com/dlmanning/gulp-sass/pull/51#issuecomment-55730711).

    gulp.task 'css', ->
      gulp.src 'scss/onestopsource.scss'
      .pipe ifElse Debug, sourcemaps.init
      .pipe sass()
      .pipe ifElse Debug, sourcemaps.write
      .pipe ifElse Debug, () -> sourcemaps.init loadMaps: true  # must be lazy
      .pipe autoprefixer
        browsers: ['last 2 versions', '> 1%'],
        cascade: false
      .pipe ifElse Debug, sourcemaps.write, minify minifyCss
      .pipe gulp.dest Destination.css
      .pipe reload stream: true

**files** -- Copy static files

    gulp.task 'files', ->
      gulp.src Source.files
      .pipe gulp.dest BuildRoot


**serve** -- Start serving static files and watch for file changes.

    gulp.task 'serve', ['debug-mode', 'build'], ->
      browserSync.init
        server:
          baseDir: BuildRoot

      gulp.watch Source.jade, ['html']
      gulp.watch Source.scss, ['css']
      gulp.watch Source.files, ['files']

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
