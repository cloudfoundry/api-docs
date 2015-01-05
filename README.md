Cloud Controller API Docs
========

This is a small sinatra application used to link to different versions of the Cloud Controller API docs.

Instructions for adding docs for a new release
--------
1. Go to the github page for [cf-release](https://github.com/cloudfoundry/cf-release)
2. Find the tag for the release you want.
3. Go into the `src` directory.
4. Get the SHA for the `cloud_controller_ng` submodule.
5. Go to the Travis page for [cloud\_controller\_ng](https://travis-ci.org/cloudfoundry/cloud_controller_ng/builds)
6. Find the build that corresponds to the SHA you have.
7. Click on that build and get the build ID out of the URL. It should be at least 8 digits long.
8. Update the hash at the top of `main.rb` and add the release number and Travis build ID.
