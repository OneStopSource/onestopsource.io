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
    DisableScssLint = false  # scss linter requires ruby gem

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
      scss_main: 'scss/onestopsource.scss'
      files: 'files/**'

Dependencies
------------

Core:

    gulp = require 'gulp'
    gutil = require 'gulp-util'
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
    rev    = require 'gulp-rev'
    collect = require 'gulp-rev-collector'

Style checkers:

    coffeelint = require 'gulp-coffeelint'
    scsslint = require 'gulp-scss-lint'

[BrowserSync][] development server:

    browserSync = require('browser-sync').create()
    reload      = browserSync.reload

Utils

    clean = require 'gulp-rimraf'
    runSequence = require 'run-sequence'

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

    gulp.task 'build', ->
      runSequence 'clean', 'html', 'css', 'files', 'revision', 'collect'
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

**css** -- Compile [Sass][] files to CSS. Include source maps in debug mode.
Note: You *really* need to generate sourcemaps twice. There's a bug in
gulp-sass, gulp-autprefixer or gulp-sourcemaps (dunno which one). See
[issue](https://github.com/dlmanning/gulp-sass/pull/51#issuecomment-55730711).

    gulp.task 'css', ->
      gulp.src Source.scss_main
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


**clean** -- Clean the build dir

    gulp.task 'clean', ->
      gulp.src [BuildRoot + '/*', 'rev-manifest.json']
      .pipe clean({read: false})

**revision** changed static files browser inmediatelly loads

    gulp.task 'revision', ->
      if Debug
        return
      gulp.src BuildRoot + '/**/*.{css,js,jpg,gif,png}'
      .pipe rev()
      .pipe gulp.dest BuildRoot
      .pipe rev.manifest()
      .pipe gulp.dest '.'

    gulp.task 'collect', ->
      if Debug
        return
      gulp.src ['rev-manifest.json', BuildRoot + '/**/*.{html,xml,txt,json,css,js}']
      .pipe collect()
      .pipe gulp.dest BuildRoot

**serve** -- Start serving static files and watch for file changes.

    gulp.task 'serve', ['debug-mode', 'build'], ->
      browserSync.init
        server:
          baseDir: BuildRoot

      gulp.watch Source.jade, ['html']
      gulp.watch Source.scss, ['css', 'lint:scss']
      gulp.watch Source.files, ['files']

**ci** -- Check for any problems: Try to build all assets, run tests and check
coding style.

    gulp.task 'ci', ['build', 'lint']

**lint** – Run all linters

    gulp.task 'lint', ['lint:scss', 'lint:coffee']

**lint:sass** -- Check coding style of SCSS scripts (requires `scss-lint` ruby
gem)

    gulp.task 'lint:scss', ->
      return if DisableScssLint

      gulp.src Source.scss_main
      .pipe scsslint config: 'scss_lint_config.yml'
      .on 'error', (error) ->
        msg = 'Missing ruby gem, run `gem install scss-lint`' +
              ' to enable scss linter and restart gulp.'
        gutil.log gutil.colors.yellow msg

        DisableScssLint = true  # temporary disable linter
        this.emit 'end'
      .pipe ifElse !Debug, scsslint.failReporter

**lint:coffee** -- Check coffeescripts for coding style violations

    gulp.task 'lint:coffee', ->
      gulp.src [
        'gulpfile.litcoffee'
      ]
      .pipe coffeelint()
      .pipe coffeelint.reporter()
      .pipe coffeelint.reporter 'fail'
