Cloud Controller API Docs
========

This is a small sinatra application that we use to scrape the latest passing build of cloud controller for the generated docs s3 link and display it in an iframe.

Known Issues
--------
* This displays the latest CC build that has passed travis, not the latest deployed CC in cf-release
* Travis only provides a limited number of builds to the api, if the build fails for a long enough time, the docs will not be scraped
* This was authored by the runtime PM, not the runtime dev team
