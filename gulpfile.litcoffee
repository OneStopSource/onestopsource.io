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

    coffeelint = require 'gulp-coffeelint'
    bytediff = require 'gulp-bytediff'
    minifyHTML = require 'gulp-minify-html'

Load [BrowserSync][] for serving static files, automatic
reloading and synchronization of multiple browsers:

    browserSync = require('browser-sync').create()
    reload      = browserSync.reload

Publish static assets to AWS S3 bucket and load AWS IAM credentials:

    s3 = require 'gulp-s3'
    fs = require("fs")

Tasks
-----

The **default** task builds all static assets, runs local server at :3000
and watches for changes. Use **build** task for one-time build.

    gulp.task 'build', ['html', 'files']
    gulp.task 'default', ['build', 'serve']

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
      gulp.src 'jade/**/*.jade'
      .pipe jade pretty: true
      .pipe(bytediff.start())
      .pipe(minifyHTML(opts))
      .pipe(bytediff.stop())
      .pipe gulp.dest Destination


**files** -- Copy static files

    gulp.task 'files', ->
      gulp.src 'files/**/*'
      .pipe gulp.dest Destination


**serve** -- Start serving static files and watch for file changes.

    gulp.task 'serve', ->
      browserSync.init
        server:
          baseDir: Destination
      gulp.watch 'jade/**/*.jade', ['reload:jade']
      gulp.watch 'files/**/*', ['files']

**reload:jade** -- Reload browser after new html is compiled.

    gulp.task 'reload:jade', ['html'], reload

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
