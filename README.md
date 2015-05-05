OneStopSource.io homepage
=========================

Static homepage of One Stop Source, independent developers.


Contribute
----------

1. Setup development environment:

    ```
    npm install -g gulp bower
    npm install
    bower install
    ```

2. Run *watcher* (it opens browser at http://localhost:3000):

    ```
    gulp
    ```

3. Commit changes and submit pull-request

Publish to AWS S3 (authorization required)
------------------------------------------

1. Copy `aws.json.example` to `aws.json` and provide credentials for your
   AWS IAM role.

2. Build all static assets and publish them to S3:

    ```
    gulp publish
    ```

License
-------

MIT
